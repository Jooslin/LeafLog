//
//  CommunityComposeReactor.swift
//  LeafLog
//
//  Created by 변예린 on 7/9/26.
//

import UIKit
import ReactorKit
import Supabase
import Dependencies

final class CommunityComposeReactor: Reactor {
    enum Action {
        case viewWillAppear
        case selectCategory(Int)
        case enterTitle(String)
        case enterBody(String)
        
        case addPictures([UIImage])
        case replacePicture(index: Int, image: UIImage)
        case removePicture(index: Int)
        case movePicture(from: Int, to: Int)
    }
    
    enum Mutation {
        case setCategory(PostCategory)
        case setTitle(String)
        case setBody(String)
        
        case appendPictures([UIImage])
        case replacePicture(index: Int, image: UIImage)
        case removePicture(index: Int)
        case movePicture(from: Int, to: Int)
    }
    
    struct State {
        var category: PostCategory
        var title: String = ""
        var pictures: [UIImage] = []
        var body: String = ""
        
        var isButtonActive: Bool {
            !title.isEmpty && !body.isEmpty
        }
    }
    
    let initialState = State(category: .plantLife)
    
    //MARK: Properties
    private let calendar = Calendar.current
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewWillAppear:
            return .empty()
        case .selectCategory(let tag):
            return
                .just(.setCategory(PostCategory(rawValue: tag) ?? .plantLife))
        case .enterTitle(let title):
            return .just(.setTitle(title))
        case .addPictures(let pictures):
            return .just(.appendPictures(pictures))
        case let .replacePicture(index, image):
            return .just(.replacePicture(index: index, image: image))
        case .removePicture(let index):
            return .just(.removePicture(index: index))
        case let .movePicture(from, to):
            return .just(.movePicture(from: from, to: to))
        case .enterBody(let body):
            return .just(.setBody(body))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setCategory(let category):
            newState.category = category
        case .setTitle(let title):
            newState.title = title
        case .appendPictures(let pictures):
            newState.pictures.append(contentsOf: pictures)
        case let .replacePicture(index, image):
            guard newState.pictures.indices.contains(index) else {
                return state
            }
            newState.pictures[index] = image
        case .removePicture(let index):
            guard newState.pictures.indices.contains(index) else {
                return state
            }
            newState.pictures.remove(at: index)
        case let .movePicture(from, to):
            guard
                newState.pictures.indices.contains(from),
                newState.pictures.indices.contains(to)
            else {
                return state
            }
            let picture = newState.pictures.remove(at: from)
            newState.pictures.insert(picture, at: to)
        case .setBody(let body):
            newState.body = body
        }
        return newState
    }
}
