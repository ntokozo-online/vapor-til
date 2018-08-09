import Vapor
import Leaf

struct WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        router.get(use: indexHandler)
        router.get("acronyms", Acronym.parameter, use: acronymHandler)
    }
    
    func indexHandler(_ request: Request) throws -> Future<View> {
        return Acronym.query(on: request)
            .all()
            .flatMap(to: View.self) { acronyms in
                let acronymsData = acronyms.isEmpty ? nil : acronyms
                let context = IndexContext(title: "Homepage", acronyms: acronymsData)
                return try request.view().render("index", context)
            }
    }
    
    func acronymHandler(_ request: Request) throws -> Future<View> {
        return try request.parameters.next(Acronym.self)
            .flatMap(to: View.self) { acronym in
                return acronym.user
                    .get(on: request)
                    .flatMap(to: View.self) { user in
                        let context = AcronymContext(title: acronym.short,
                                                     acronym: acronym,
                                                     user: user)
                        return try request.view().render("acronym", context)
                }
            }
    }
}

struct IndexContext: Encodable {
    let title: String
    let acronyms: [Acronym]?
}

struct AcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    let user: User
}
