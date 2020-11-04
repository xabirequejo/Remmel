//
//  PostScreenUI.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 9/26/20.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import SafariServices

class PostScreenUI: UIView {
    
    var presentOnVc: ((UIViewController) -> Void)?
    var dismissOnVc: (() -> Void)?
    
    let tableView = LemmyTableView(style: .plain)

    let postInfo: LemmyApiStructs.PostView
    var commentsDataSource: [LemmyApiStructs.CommentView] = [] {
        didSet {
            self.commentListing = CommentListingSort(comments: self.commentsDataSource)
            self.commentTrees = commentListing?.createTreeOfReplies()

            DispatchQueue.main.async {
                self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
            }
        }
    }

    private var commentListing: CommentListingSort?
    private var commentTrees: [CommentNode]?

    init(post: LemmyApiStructs.PostView) {
        self.postInfo = post
        super.init(frame: .zero)

        self.addSubview(tableView)

        tableView.delegate = self
        tableView.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        self.tableView.snp.makeConstraints { (make) in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
    }
    
    private func openLink(urlString: String?) {
        if let str = urlString, let url = URL(string: str) {
            
            let sfConfig = SFSafariViewController.Configuration()
            sfConfig.entersReaderIfAvailable = true

            let vc = SFSafariViewController(url: url, configuration: sfConfig)
            vc.delegate = self

            presentOnVc?(vc)
        }
    }
}

extension PostScreenUI: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.dismissOnVc?()
    }
}

extension PostScreenUI: UITableViewDelegate, UITableViewDataSource {
    enum PostScreenTableCellType: Equatable, Comparable, CaseIterable {
        case post, comments
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return PostScreenTableCellType.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let types = PostScreenTableCellType.allCases[section]

        switch types {
        case .post:
            return 1
        case .comments:
            if let commentTrees = commentTrees {
                return commentTrees.count
            }
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let types = PostScreenTableCellType.allCases[indexPath.section]

        switch types {
        case .post:
            let cell = PostScreenUITableCell(post: postInfo)
            cell.postGreenOutlineView.addTap {
                self.openLink(urlString: cell.postGreenOutlineView.viewData.url)
            }
            return cell
        case .comments:
            guard let commentTrees = commentTrees else { return UITableViewCell() }

            let cell = CommentTreeTableCell(commentNode: commentTrees[indexPath.row])
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

private class PostScreenUITableCell: UITableViewCell {
    let postHeaderView = PostContentView()
    private(set) lazy var postGreenOutlineView = LemmyGreenOutlinePostEmbed(
        with:
            LemmyGreenOutlinePostEmbed.Data(
                title: postInfo.embedTitle,
                description: postInfo.embedDescription,
                url: postInfo.url
            )
    )

    let postInfo: LemmyApiStructs.PostView

    init(post: LemmyApiStructs.PostView) {
        self.postInfo = post
        super.init(style: .default, reuseIdentifier: nil)

        createSubviews()
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createSubviews() {
        // post header view
        postHeaderView.bind(with: postInfo)
        postHeaderView.setupUIForPost()

        self.contentView.addSubview(postHeaderView)
        self.contentView.addSubview(postGreenOutlineView)

        self.postHeaderView.snp.makeConstraints { (make) in
            make.top.trailing.leading.equalToSuperview()
        }

        if !postGreenOutlineView.isHidden {
            self.postGreenOutlineView.snp.makeConstraints { (make) in
                make.top.equalTo(postHeaderView.snp.bottom).offset(10)
                make.trailing.leading.equalToSuperview().inset(10)
                make.bottom.equalToSuperview()
            }
        } else {
            self.postHeaderView.snp.remakeConstraints { (make) in
                make.top.trailing.leading.bottom.equalToSuperview()
            }
        }
    }

    func setupUI() {
        self.backgroundColor = UIColor.systemBackground
        self.selectionStyle = .none
    }
}
