//
//  AsyncContentView.swift
//  BuyersCircle-iOS
//
//  Created by liang wang on 16/5/21.
//

import Combine
import SwiftUI

// MARK: - common

enum PageError: Error {
    // General Error
    case genericError

    // API Error
    case apiError(reason: String)
    
    
    var errorDescription: String {
        switch self {
        case .apiError(reason: _):
            return "Something is wrong"
        case .genericError:
            return "Something is wrong"
        }
    }
}

struct PageErrorView: View {
    var error: PageError
    var retryHandler: (() -> Void)?
    var body: some View {
        VStack(spacing: 0) {
            Text(error.errorDescription).font(.body)
            Button("Retry") {
                retryHandler?()
            }.frame(width: 150, height: 40)
        }
    }
}

typealias DefaultProgressView = ProgressView<EmptyView, EmptyView>

// MARK: - Abstracted state and model

enum PageLoadingState<Value> {
    case idle
    case loading
    case failed(PageError)
    case success(Value)
}

protocol PageLoadableObject: ObservableObject {
    associatedtype Output

    var outputResult: PageLoadingState<Output> { get }

    func load()
}

struct AsyncContentView<Source: PageLoadableObject, LoadingView: View, Content: View>: View {
    @ObservedObject var source: Source
    var content: (Source.Output) -> Content
    var loadingView: LoadingView

    init(source: Source,
         loadingView: LoadingView,
         @ViewBuilder content: @escaping (Source.Output) -> Content)
    {
        self.source = source
        self.loadingView = loadingView
        self.content = content
    }

    var body: some View {
        switch source.outputResult {
        case .idle:
            Color.white // You can not use EmptyView here
        case .loading:
            loadingView
        case let .failed(error):
            PageErrorView(error: error, retryHandler: retryHandler)
        case let .success(output):
            content(output)
        }
    }

    func retryHandler() {
        source.load()
    }
}

extension AsyncContentView where LoadingView == DefaultProgressView {
    init(
        source: Source,
        @ViewBuilder content: @escaping (Source.Output) -> Content
    ) {
        self.init(
            source: source,
            loadingView: DefaultProgressView(),
            content: content
        )
    }
}

// MARK： - a real demo

 struct Article {
    var title: String = ""
    var body: String = ""
}

class ArticleViewDemoModel: PageLoadableObject {

    // Output result
    @Published var outputResult: PageLoadingState<Article> = .idle

    func load() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.outputResult = .loading
            print("loading begin after 2 seconds")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.outputResult = .success(Article(title: "success loaded", body: "this is a successfully result"))
            print("loaded success after 4 seconds")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            self.outputResult = .failed(.genericError)
            print("loaded failure after 6 seconds")
        }
    }

    static let shared = ArticleViewDemoModel()
}

struct ArticleViewDemo: View {
    @ObservedObject var viewModel = ArticleViewDemoModel()

    @State private var id = 1

    var body: some View {
        AsyncContentView(source: viewModel) { article in
            ScrollView {
                VStack(spacing: 20) {
                    Text(article.title).font(.title)
                    Text(article.body)
                }
                .foregroundColor(Color.pink)
                .padding()
            }
        }.onAppear(perform: {
            print("ArticleViewDemo onAppear")
            viewModel.load()
        })
    }
}

struct ArticleViewDemo_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ArticleViewDemo()
            PageErrorView(error: .genericError)
        }
    }
}
