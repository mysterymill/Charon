use actix_web::{get, post, web, App, HttpResponse, HttpServer, Responder};

mod http;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        App::new()
            .service(http::config::hello)
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}