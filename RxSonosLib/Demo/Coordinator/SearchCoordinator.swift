//
//  SearchCoordinator.swift
//  Demo App
//
//  Created by Stefan Renne on 10/04/2018.
//  Copyright © 2018 Uberweb. All rights reserved.
//

import UIKit
import RxSonosLib

protocol SearchRouter {
    
}

class SearchCoordinator: BaseCoordinator {
    
    private let tabbarRouter: TabBarRouter
    init(navigationController: UINavigationController?, tabbarRouter: TabBarRouter) {
        self.tabbarRouter = tabbarRouter
        super.init(navigationController: navigationController)
    }
    
    private let viewController = SearchViewController()
    override func setup() -> UIViewController {
        viewController.router = self
        return viewController
    }
    
    func start() {
        let viewController = self.setup()
        self.navigationController?.setViewControllers([viewController], animated: false)
    }
    
}

extension SearchCoordinator: SearchRouter {
    
}
