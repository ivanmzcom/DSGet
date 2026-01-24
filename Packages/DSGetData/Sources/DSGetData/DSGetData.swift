// DSGetData - Data Layer Module
// Provides implementations for repository protocols and data access

import Foundation

// Re-export DSGetDomain for convenience
@_exported import DSGetDomain

// MARK: - Public API

/*
 This module exports:

 # DTOs (Data Transfer Objects)
 - SynoResponseDTO, SynoErrorDTO, EmptyDataDTO
 - DownloadTaskDTO, TaskListResponseDTO, TaskAdditionalDTO, TaskDetailDTO, TaskTransferDTO, TaskFileDTO, TaskTrackerDTO, TaskEditResultDTO
 - RSSFeedDTO, RSSFeedIDDTO, RSSSiteListDTO, RSSFeedItemDTO, RSSFeedItemsListDTO, RSSFeedItemEnclosureDTO
 - LoginResponseDTO, APIConfigurationDTO
 - FileStationFileDTO, FileStationAdditionalDTO, FileStationOwnerDTO, FileStationTimeDTO, FileStationShareListDTO, FileStationFileListDTO, FileStationFileInfoDTO

 # Mappers
 - TaskMapper, FeedMapper, FileMapper, AuthMapper, ErrorMapper

 # Network Layer
 - NetworkClientProtocol, NetworkClient
 - MultipartFormData
 - NetworkMonitorImpl

 # Data Sources (Local)
 - SecureStorageProtocol, KeychainDataSource, KeychainError
 - InMemoryCacheDataSource

 # Data Sources (Remote)
 - SynologyAPIClient
 - TaskRemoteDataSource, SynologyTaskDataSource
 - FeedRemoteDataSource, SynologyFeedDataSource
 - AuthRemoteDataSource, SynologyAuthDataSource
 - FileRemoteDataSource, SynologyFileDataSource

 # Repository Implementations
 - TaskRepositoryImpl
 - FeedRepositoryImpl
 - AuthRepositoryImpl
 - FileSystemRepositoryImpl

 # Errors
 - DataError, NetworkError
*/
