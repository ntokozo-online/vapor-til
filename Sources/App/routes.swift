import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { request in
        return "Hello, world!"
    }
    
    // Create
    router.post("api", "acronyms") { request -> Future<Acronym> in
        return try request.content.decode(Acronym.self).flatMap({ acronym in
            return acronym.save(on: request)
        })
    }
    
    // Retrieve all
    router.get("api", "acronyms") { request -> Future<[Acronym]> in
        return Acronym.query(on: request).all()
    }
    
    // Retrieve an acronym
    router.get("api", "acronyms", Acronym.parameter) { request -> Future<Acronym> in
        return try request.parameters.next(Acronym.self)
    }
    
    // Update
    router.put("api", "acronyms", Acronym.parameter) { request -> Future<Acronym> in
        return try flatMap(
        to: Acronym.self, request.parameters.next(Acronym.self),
        request.content.decode(Acronym.self)
        ) { acronym, updatedAcronym in
            acronym.short = updatedAcronym.short
            acronym.long = updatedAcronym.long
            return acronym.save(on: request)
        }
    }
    
    // Delete an acronym
    router.delete("api", "acronyms", Acronym.parameter) { request -> Future<HTTPStatus> in
        return try request.parameters.next(Acronym.self).delete(on: request).transform(to: HTTPStatus.noContent)
    }
    
    // Search using multiple fields
    router.get("api", "acronyms", "search") { request -> Future<[Acronym]> in
        guard let searchTerm = request.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        return Acronym.query(on: request).group(.or) { or in
            or.filter(\.short == searchTerm)
            or.filter(\.long == searchTerm)
        }.all()
        
        // To search on a single field
        //return Acronym.query(on: request).filter(\.short == searchTerm).all()
    }
    
    // Retrieve first acronym
    router.get("api", "acronyms", "first") { request -> Future<Acronym> in
        return Acronym.query(on: request)
            .first()
            .map(to: Acronym.self) { acronym in
                guard let acronym = acronym else {
                    throw Abort(.notFound)
                }
                
                return acronym
        }
    }
    
    // Sorting results
    router.get("api", "acronyms", "sorted") { request -> Future<[Acronym]> in
        return Acronym.query(on: request).sort(\.short, .ascending).all()
    }
}
