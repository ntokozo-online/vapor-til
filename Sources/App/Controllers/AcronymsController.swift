import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")
        acronymsRoutes.get(use: getAllHandler)
        acronymsRoutes.post(Acronym.self, use: createHandler)
        acronymsRoutes.get(Acronym.parameter, use: getHandler)
        acronymsRoutes.put(Acronym.parameter, use: updateHandler)
        acronymsRoutes.delete(Acronym.parameter, use: deleteHandler)
        acronymsRoutes.get("search", use: searchHandler)
        acronymsRoutes.get("first", use: getFirstHandler)
        acronymsRoutes.get("sorted", use: sortedHandler)
        acronymsRoutes.get(Acronym.parameter, "user", use: getUserHandler)
    }
    
    func getAllHandler(_ request: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: request).all()
    }
    
    func createHandler(_ request: Request, acronym: Acronym) throws -> Future<Acronym> {
        return acronym.save(on: request)
    }
    
    func getHandler(_ request: Request) throws -> Future<Acronym> {
        return try request.parameters.next(Acronym.self)
    }
    
    func updateHandler(_ request: Request) throws -> Future<Acronym> {
        return try flatMap(to: Acronym.self,
                           request.parameters.next(Acronym.self),
                           request.content.decode(Acronym.self)) {
            acronym, updatedAcronym in
            acronym.short = updatedAcronym.short
            acronym.long = updatedAcronym.long
            acronym.userID = updatedAcronym.userID
            return acronym.save(on: request)
        }
    }
    
    func deleteHandler(_ request: Request) throws -> Future<HTTPStatus> {
        return try request.parameters
            .next(Acronym.self)
            .delete(on: request)
            .transform(to: HTTPStatus.noContent)
    }
    
    func searchHandler(_ request: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = request.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        return Acronym.query(on: request).group(.or) { or in
            or.filter(\.short == searchTerm)
            or.filter(\.long == searchTerm)
        }.all()
        
        // To search a single field
        // return Acronym.query(on: request).filter(\.short == searchTerm).all()
    }
    
    func getFirstHandler(_ request: Request) throws -> Future<Acronym> {
        return Acronym.query(on: request).first().map(to: Acronym.self) { acronym in
            guard let acronym = acronym else {
                throw Abort(.notFound)
            }
            
            return acronym
        }
    }
    
    func sortedHandler(_ request: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: request)
            .sort(\.short, .ascending)
            .all()
    }
    
    func getUserHandler(_ request: Request) throws -> Future<User> {
        return try request.parameters.next(Acronym.self).flatMap(to: User.self) { acronym in
            acronym.user.get(on: request)
        }
    }
}
