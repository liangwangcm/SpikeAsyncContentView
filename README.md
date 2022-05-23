# Description

A stateful view could handle following situations:
- loading view
- error view
- content that is loaded from view model

## Limitation

1. Only one state and one load

`PageLoadableObject` allows only one `outputResult` and one `load`. That means if your view model has > 1 load(fetch networking etc) logic, you can not use it.

In this case, I recommend you to split your view model into smaller ones.

2. No input parameter (`load()`)

As a workaround, you can create another variable in your view model and do this way

```swift
class ArticleViewDemoModel: PageLoadableObject {

    // Input
    var pageNumber: Int = 0

    // Output result
    @Published var outputResult: PageLoadingState<Article> = .idle
    
    func load() {
       fetch(pageNumber: pageNumber)
       ...
    }
```

