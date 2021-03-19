//
//  UserAccountService.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 14.11.2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit

protocol UserAccountSerivceProtocol {
    var currentUser: LMModels.Views.LocalUserSettingsView? { get set }
    var currentUserID: LMModels.Views.LocalUserSettingsView.ID? { get }
    var isAuthorized: Bool { get }
    var jwtToken: String? { get set }

    func logOut()
    func userLogout() // logout but not clearing currentInstanceUrl
}

// wrapper 
final class UserAccountService: UserAccountSerivceProtocol {
    var currentUser: LMModels.Views.LocalUserSettingsView? {
        get { LemmyShareData.shared.userdata }
        set { LemmyShareData.shared.userdata = newValue }
    }
    
    var currentUserID: LMModels.Views.LocalUserSettingsView.ID? { LemmyShareData.shared.userdata?.id }
    
    var jwtToken: String? {
        get { LemmyShareData.shared.jwtToken }
        set { LemmyShareData.shared.jwtToken = newValue }
    }
    
    var isAuthorized: Bool { LemmyShareData.shared.isLoggedIn }
    
    func logOut() { LemmyShareData.shared.loginData.logout() }
    
    func userLogout() { LemmyShareData.shared.loginData.userLogout() }
}
