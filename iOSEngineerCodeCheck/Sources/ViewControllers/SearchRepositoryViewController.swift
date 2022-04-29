//
//  ViewController.swift
//  iOSEngineerCodeCheck
//
//  Created by 史 翔新 on 2020/04/20.
//  Copyright © 2020 YUMEMI Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class SearchRepositoryViewController: UIViewController {

    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    private var viewModel: SearchRepositoryViewModelType!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bindUI()
    }

    static func configure() -> SearchRepositoryViewController {
        let viewController = StoryboardScene.SearchRepository.searchRepository.instantiate()
        viewController.viewModel = SearchRepositoryViewModel(model: SearchRepositoryModel())
        return viewController
    }

    private func setup() {
        activityIndicatorView.hidesWhenStopped = true
        tableView.registerCustomCell(RepositoryCell.self)
        tableView.keyboardDismissMode = .onDrag
        searchBar.placeholder = L10n.SearchBar.Initial.message
    }

    private func bindUI() {

        /* Input */
        Observable.zip(
            tableView.rx.modelSelected(Repository.self),
            tableView.rx.itemSelected
        ).subscribe(onNext: { [weak self] repository, indexPath in
            self?.tableView.deselectRow(at: indexPath, animated: true)
            self?.transitionToRepositoryDetail(repository: repository)
        }).disposed(by: disposeBag)

        searchBar.rx.text.orEmpty.asDriver()
            .filter { $0.count > 0 }
            .throttle(.seconds(1))
            .withLatestFrom(viewModel.outputs.isLoadingDriver)
            .drive(onNext: { [weak self] isLoading in
                /* isLoading = trueの場合にはAPI呼び出しをしない */
                guard let self = self, !isLoading else { return }
                /* filterでnilチェックしているので強制アンラップ */
                self.viewModel.inputs.searchRepository(keyword: self.searchBar.text!)
            }).disposed(by: disposeBag)

        searchBar.rx.searchButtonClicked.asSignal()
            .emit(onNext: { [weak self] _ in
                self?.searchBar.resignFirstResponder()
            }).disposed(by: disposeBag)

        /* Output */
        viewModel.outputs.isLoadingDriver
            .drive(activityIndicatorView.rx.isAnimating)
            .disposed(by: disposeBag)

        viewModel.outputs.repositoriesDriver
            .drive(tableView.rx.items(cellIdentifier: RepositoryCell.identifier, cellType: RepositoryCell.self)) { index, repository, cell in
                cell.configure(repository: repository)
            }.disposed(by: disposeBag)

        viewModel.outputs.errorDriver
            .drive(onNext: { [weak self] error in
                self?.showError("エラー", message: error.localizedDescription)
            }).disposed(by: disposeBag)
    }

    private func transitionToRepositoryDetail(repository: Repository) {
        let viewController = RepositoryDetailViewController.configure(repository: repository)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
