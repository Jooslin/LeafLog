//
//  AppUpdateManager.swift
//  LeafLog
//
//  Created by 김주희 on 5/1/26.
//

import Dependencies
import Foundation
import OSLog
import Supabase

// MARK: - Supabase 정책 조회 + 버전 판단

enum AppUpdateState {
    case available // 업데이트 필요 없음
    case optional(storeURL: URL) // 업데이트 가능 (선택)
    case required(message: String, storeURL: URL) // 업데이트 (필수)
}

final class AppUpdateManager {
    @Dependency(\.supabaseManager) private var supabaseManager

    private let logger = Logger(subsystem: "LeafLog", category: "AppUpdateManager")

    private init() {}

    // MARK: - 업데이트 해야하는지 확인하는 메서드
    func fetchUpdateState() async -> AppUpdateState {
        do {
            // 서버에서 정책 가져오기
            guard let policy = try await fetchPolicy() else {
                return .available
            }

            return makeUpdateState(from: policy)
        } catch {
            logger.error("업데이트 정책 조회 실패: \(error.localizedDescription, privacy: .private)")
            return .available
        }
    }

    // MARK: - 서버에서 정책(policy) 가져오기
    private func fetchPolicy() async throws -> AppUpdatePolicy? {
        let policies: [AppUpdatePolicy] = try await supabaseManager.client
            .from("app_update_policy")
            .select()
            .eq("platform", value: AppUpdatePlatform.ios)
            .eq("is_enabled", value: true)
            .limit(1)
            .execute()
            .value

        return policies.first
    }

    // MARK: - 업데이트 판단 로직
    private func makeUpdateState(from policy: AppUpdatePolicy) -> AppUpdateState {
        // 1. 현재 내 앱 버전, 앱스토어 주소 변환
        guard
            let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let storeURL = URL(string: policy.storeURL)
        else {
            return .available
        }

        // 2. 강제 업데이트 검사 (최소 요구 버전보다 낮을때)
        if VersionComparator.isVersion(currentVersion, lowerThan: policy.minimumRequiredVersion) {
            return .required(message: policy.forceUpdateMessage, storeURL: storeURL)
        }

        // 3. 선택 업데이트 검사 (최신 버전보다 낮을때)
        if VersionComparator.isVersion(currentVersion, lowerThan: policy.latestVersion) {
            return .optional(storeURL: storeURL)
        }

        return .available
    }
}

private enum AppUpdatePlatform {
    static let ios = "ios"
}

private struct AppUpdatePolicy: Decodable {
    let latestVersion: String
    let minimumRequiredVersion: String
    let storeURL: String
    let forceUpdateMessage: String

    enum CodingKeys: String, CodingKey {
        case latestVersion = "latest_version"
        case minimumRequiredVersion = "minimum_required_version"
        case storeURL = "store_url"
        case forceUpdateMessage = "force_update_message"
    }
}

extension AppUpdateManager: DependencyKey {
    static var liveValue: AppUpdateManager {
        AppUpdateManager()
    }
}

extension DependencyValues {
    var appUpdateManager: AppUpdateManager {
        get { self[AppUpdateManager.self] }
        set { self[AppUpdateManager.self] = newValue }
    }
}
