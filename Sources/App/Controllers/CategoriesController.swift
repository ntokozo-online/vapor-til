import Vapor

struct CategoriesController: RouteCollection {
    func boot(router: Router) throws {
        let categoriesRoute = router.grouped("api", "categories")
        categoriesRoute.post(Category.self, use: createHandler)
        categoriesRoute.get(use: getAllHandler)
        categoriesRoute.get(Category.parameter, use: getHandler)
        categoriesRoute.get(Category.parameter, "acronyms", use: getAcronymsHandler)
    }
    
    func createHandler(_ request: Request, category: Category) throws -> Future<Category> {
        return category.save(on: request)
    }
    
    func getAllHandler(_ request: Request) throws -> Future<[Category]> {
        return Category.query(on: request).all()
    }
    
    func getHandler(_ request: Request) throws -> Future<Category> {
        return try request.parameters.next(Category.self)
    }
    
    func getAcronymsHandler(_ request: Request) throws -> Future<[Acronym]> {
        return try request.parameters.next(Category.self).flatMap(to: [Acronym].self) { category in
            try category.acronyms.query(on: request).all()
        }
    }
}
