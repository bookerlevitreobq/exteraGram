import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AccountContext
import SearchBarNode
import SearchUI
import AnimationCache
import MultiAnimationRenderer
import AppBundle

private let searchBarFont = Font.regular(17.0)

public final class FocusTabController: ViewController {
    private let context: AccountContext

    private var searchBarNode: SearchBarNode?
    private var searchContainerNode: ChatListSearchContainerNode?

    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?

    private var validLayout: ContainerViewLayout?
    private var hasAppeared = false

    private let openMessageFromSearchDisposable = MetaDisposable()

    public init(context: AccountContext) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }

        super.init(navigationBarPresentationData: nil)

        self.tabBarItem.title = "Focus"
        let icon = UIImage(bundleImageName: "Chat List/Tabs/IconFocus")
        self.tabBarItem.image = icon
        self.tabBarItem.selectedImage = icon

        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).startStrict(next: { [weak self] presentationData in
            guard let self else { return }
            self.presentationData = presentationData
        })
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.presentationDataDisposable?.dispose()
        self.openMessageFromSearchDisposable.dispose()
    }

    override public func loadDisplayNode() {
        self.displayNode = ASDisplayNode()
        self.displayNode.backgroundColor = self.presentationData.theme.chatList.backgroundColor

        self.setupSearchBar()
        self.setupSearchContainer()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !self.hasAppeared {
            self.hasAppeared = true
            self.searchBarNode?.activate()
        }
    }

    private func setupSearchBar() {
        let theme = SearchBarNodeTheme(theme: self.presentationData.theme)
        let searchBarNode = SearchBarNode(
            theme: theme,
            presentationTheme: self.presentationData.theme,
            strings: self.presentationData.strings,
            fieldStyle: .modern,
            forceSeparator: true,
            displayBackground: true
        )
        searchBarNode.hasCancelButton = false
        searchBarNode.placeholderString = NSAttributedString(
            string: self.presentationData.strings.Common_Search,
            font: searchBarFont,
            textColor: self.presentationData.theme.rootController.navigationSearchBar.inputPlaceholderTextColor
        )

        searchBarNode.textUpdated = { [weak self] text, _ in
            self?.searchContainerNode?.searchTextUpdated(text: text)
        }
        searchBarNode.textReturned = { [weak self] text in
            self?.searchContainerNode?.searchTextUpdated(text: text)
        }

        self.searchBarNode = searchBarNode
        self.displayNode.addSubnode(searchBarNode)
    }

    private func setupSearchContainer() {
        let animationCache = self.context.animationCache
        let animationRenderer = self.context.animationRenderer

        let filter: ChatListNodePeersFilter = [.excludeTopPeers]

        let contentNode = ChatListSearchContainerNode(
            context: self.context,
            animationCache: animationCache,
            animationRenderer: animationRenderer,
            filter: filter,
            requestPeerType: nil,
            location: .chatList(groupId: .root),
            folder: nil,
            displaySearchFilters: false,
            hasDownloads: false,
            initialFilter: .chats,
            openPeer: { [weak self] peer, _, threadId, dismissSearch in
                self?.openPeer(peer: peer, threadId: threadId)
            },
            openDisabledPeer: { _, _, _ in },
            openRecentPeerOptions: { [weak self] peer in
                self?.openRecentPeerOptions(peer: peer)
            },
            openMessage: { [weak self] peer, threadId, messageId, deactivateOnAction in
                self?.openMessage(peer: peer, threadId: threadId, messageId: messageId)
            },
            addContact: { [weak self] phoneNumber in
                self?.addContact(phoneNumber: phoneNumber)
            },
            peerContextAction: nil,
            present: { [weak self] c, a in
                self?.present(c, in: .window(.root), with: a)
            },
            presentInGlobalOverlay: { [weak self] c, a in
                self?.presentInGlobalOverlay(c, with: a)
            },
            navigationController: self.navigationController as? NavigationController,
            parentController: { [weak self] in
                return self
            }
        )

        contentNode.dismissSearch = { [weak self] in
            self?.searchBarNode?.text = ""
        }
        contentNode.backgroundColor = self.presentationData.theme.chatList.backgroundColor

        self.searchContainerNode = contentNode
        self.displayNode.addSubnode(contentNode)

        // Trigger initial "recent" state
        contentNode.searchTextUpdated(text: "")
    }

    // MARK: - Search Result Actions

    private func openPeer(peer: EnginePeer, threadId: Int64?) {
        let storedPeer = self.context.engine.peers.ensurePeerIsLocallyAvailable(peer: peer)
        |> map { _ -> Void in return Void() }
        self.openMessageFromSearchDisposable.set((storedPeer |> deliverOnMainQueue).startStrict(completed: { [weak self] in
            guard let self, let navigationController = self.navigationController as? NavigationController else { return }
            if case let .channel(channel) = peer, channel.isForumOrMonoForum, let threadId {
                let _ = self.context.sharedContext.navigateToForumThread(
                    context: self.context,
                    peerId: peer.id,
                    threadId: threadId,
                    messageId: nil,
                    navigationController: navigationController,
                    activateInput: nil,
                    scrollToEndIfExists: false,
                    keepStack: .never,
                    animated: true
                ).startStandalone()
            } else {
                self.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(
                    navigationController: navigationController,
                    context: self.context,
                    chatLocation: .peer(peer)
                ))
            }
        }))
    }

    private func openMessage(peer: EnginePeer, threadId: Int64?, messageId: EngineMessage.Id) {
        guard let navigationController = self.navigationController as? NavigationController else { return }
        self.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(
            navigationController: navigationController,
            context: self.context,
            chatLocation: .peer(peer),
            subject: .message(id: .id(messageId), highlight: ChatControllerSubject.MessageHighlight(quote: nil), timecode: nil, setupReply: false)
        ))
    }

    private func openRecentPeerOptions(peer: EnginePeer) {
        self.view.window?.endEditing(true)
        let actionSheet = ActionSheetController(presentationData: self.presentationData)
        actionSheet.setItemGroups([
            ActionSheetItemGroup(items: [
                ActionSheetButtonItem(title: self.presentationData.strings.Common_Delete, color: .destructive, action: { [weak actionSheet, weak self] in
                    actionSheet?.dismissAnimated()
                    if let self {
                        let _ = self.context.engine.peers.removeRecentPeer(peerId: peer.id).startStandalone()
                    }
                })
            ]),
            ActionSheetItemGroup(items: [
                ActionSheetButtonItem(title: self.presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                    actionSheet?.dismissAnimated()
                })
            ])
        ])
        self.present(actionSheet, in: .window(.root))
    }

    private func addContact(phoneNumber: String) {
        self.view.endEditing(true)
        self.context.sharedContext.openAddContact(
            context: self.context,
            peer: nil,
            firstName: "",
            lastName: "",
            phoneNumber: phoneNumber,
            label: defaultContactLabel,
            present: { [weak self] controller, arguments in
                self?.present(controller, in: .window(.root), with: arguments)
            },
            pushController: { [weak self] controller in
                (self?.navigationController as? NavigationController)?.pushViewController(controller)
            },
            completed: { }
        )
    }

    // MARK: - Layout

    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.validLayout = layout

        let topInset = (layout.statusBarHeight ?? 0.0) + 10.0
        let searchBarHeight: CGFloat = 56.0

        if let searchBarNode = self.searchBarNode {
            let searchBarFrame = CGRect(
                origin: CGPoint(x: 0.0, y: topInset),
                size: CGSize(width: layout.size.width, height: searchBarHeight)
            )
            transition.updateFrame(node: searchBarNode, frame: searchBarFrame)
            searchBarNode.updateLayout(
                boundingSize: searchBarFrame.size,
                leftInset: layout.safeInsets.left,
                rightInset: layout.safeInsets.right,
                transition: transition
            )
        }

        let contentTop = topInset + searchBarHeight
        let contentFrame = CGRect(
            origin: CGPoint(x: 0.0, y: contentTop),
            size: CGSize(
                width: layout.size.width,
                height: layout.size.height - contentTop
            )
        )

        if let searchContainerNode = self.searchContainerNode {
            transition.updateFrame(node: searchContainerNode, frame: contentFrame)
            searchContainerNode.containerLayoutUpdated(ContainerViewLayout(
                size: contentFrame.size,
                metrics: layout.metrics,
                deviceMetrics: layout.deviceMetrics,
                intrinsicInsets: UIEdgeInsets(
                    top: 0.0,
                    left: layout.safeInsets.left,
                    bottom: layout.intrinsicInsets.bottom,
                    right: layout.safeInsets.right
                ),
                safeInsets: layout.safeInsets,
                additionalInsets: layout.additionalInsets,
                statusBarHeight: nil,
                inputHeight: layout.inputHeight,
                inputHeightIsInteractivellyChanging: layout.inputHeightIsInteractivellyChanging,
                inVoiceOver: layout.inVoiceOver
            ), navigationBarHeight: 0.0, transition: transition)
        }
    }
}
