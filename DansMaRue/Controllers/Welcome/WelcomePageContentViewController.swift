//
//  WelcomePageContentViewController.swift
//  DansMaRue
//
//  Created by NTDC-Showroom on 20/03/2017.
//  Copyright © 2017 VilleDeParis. All rights reserved.
//

import UIKit

class WelcomePageContentViewController: UIPageViewController {
    // MARK: - Properties

    var pageIndex = 0
    var arrayPageTitle: NSArray = .init()
    var arrayPagePhoto: NSArray = .init()
    var arrayPageText: NSArray = .init()
    let proxy = UIPageControl.appearance()

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        
        arrayPageTitle = [Constants.LabelMessage.bienvenue,
                          Constants.LabelMessage.envoyerInfo,
                          Constants.LabelMessage.restezEnContact]
        
        arrayPagePhoto = [Constants.Image.illustration1,
                          Constants.Image.illustration2,
                          Constants.Image.illustration3]
        
        arrayPageText = [Constants.LabelMessage.textSlide1,
                         Constants.LabelMessage.textSlide2,
                         Constants.LabelMessage.textSlide3]
      
        proxy.pageIndicatorTintColor = .white
        proxy.currentPageIndicatorTintColor = UIColor(hexString: "#B1002D")
        proxy.currentPage = pageIndex
        
        setViewControllers([getViewControllerAtIndex(index: 0)] as [UIViewController], direction: UIPageViewController.NavigationDirection.forward, animated: false, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        if #available(iOS 14.0, *) {
            self.pageControl?.currentPageIndicatorTintColor = .white
            self.pageControl?.setIndicatorImage(UIImage(named: "dot_white_small"), forPage: 0)
            self.pageControl?.setIndicatorImage(UIImage(named: "dot_white_small"), forPage: 1)
            self.pageControl?.setIndicatorImage(UIImage(named: "dot_white_small"), forPage: 2)
        }
        if #available(iOS 16.0, *) {
            self.pageControl?.currentPageIndicatorTintColor = .white
            self.pageControl?.setCurrentPageIndicatorImage(UIImage(named: "dot_white_large"), forPage: 0)
            self.pageControl?.setCurrentPageIndicatorImage(UIImage(named: "dot_white_large"), forPage: 1)
            self.pageControl?.setCurrentPageIndicatorImage(UIImage(named: "dot_white_large"), forPage: 2)
        }
    }
}

// MARK: UIPageViewControllerDataSource

extension WelcomePageContentViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let pageContent: WelcomeSliderViewController = viewController as! WelcomeSliderViewController
        
        var index = pageContent.welcomePageIndex
        
        if (index == 0) || (index == NSNotFound) {
            return nil
        }
        index -= 1
        return getViewControllerAtIndex(index: index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let pageContent: WelcomeSliderViewController = viewController as! WelcomeSliderViewController
        
        var index = pageContent.welcomePageIndex
        
        if index == NSNotFound {
            return nil
        }
        index += 1
        if index == arrayPageTitle.count {
            return nil
        }
        
        return getViewControllerAtIndex(index: index)
    }
    
    func getViewControllerAtIndex(index: NSInteger) -> WelcomeSliderViewController {
        pageIndex = index
        
        let welcomeStoryboard = UIStoryboard(name: Constants.StoryBoard.welcome, bundle: nil)
        let welcomeSliderViewController = welcomeStoryboard.instantiateViewController(withIdentifier: Constants.ViewControllerIdentifier.welcome) as! WelcomeSliderViewController
        
        welcomeSliderViewController.welcomeTitleText = "\(arrayPageTitle[index])"
        welcomeSliderViewController.welcomeImage = "\(arrayPagePhoto[index])"
        welcomeSliderViewController.welcomePageIndex = index
        welcomeSliderViewController.welcomeSubtitleText = "\(arrayPageText[index])"

        return welcomeSliderViewController
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return pageIndex
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return 3
    }
}

extension UIPageViewController {
    var pageControl: UIPageControl? {
        for view in view.subviews {
            if view is UIPageControl {
                return view as? UIPageControl
            }
        }
        return nil
    }
}
