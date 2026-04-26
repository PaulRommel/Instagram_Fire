//
//  MainTabBarController.swift
//  InstagramFire
//
//  Created by Павел Попов on 26.04.2026.
//

import UIKit

@available(iOS 15.0, *)
class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Настройка внешнего вида  нав-бара
        let appearanceNavBar = UINavigationBarAppearance()
        appearanceNavBar.configureWithDefaultBackground()
        
        UINavigationBar.appearance().standardAppearance = appearanceNavBar
        UINavigationBar.appearance().scrollEdgeAppearance = appearanceNavBar
        
        // Настройка внешнего вида таб-бара
        let appearanceTabBar = UITabBarAppearance()
        appearanceTabBar.configureWithDefaultBackground()
        
        tabBar.standardAppearance = appearanceTabBar
        tabBar.scrollEdgeAppearance = appearanceTabBar
        
        let layout = UICollectionViewFlowLayout()
        let userProfileController = UserProfileController(collectionViewLayout: layout)
        
        let navController = UINavigationController(rootViewController: userProfileController)
        navController.tabBarItem.image = #imageLiteral(resourceName: "profile_unselected")
        navController.tabBarItem.selectedImage = #imageLiteral(resourceName: "profile_selected")
        
        tabBar.tintColor = .black
       
        viewControllers = [navController, UIViewController()]
    }
}
