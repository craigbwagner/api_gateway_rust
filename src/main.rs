use actix_web::{App, HttpRequest, HttpServer, Responder, web};
use reqwest::Client;
use std::sync::Arc;
use tokio::sync::Mutex;

struct AppState {
    client: Client,
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let state = Arc::new(AppState {
        client: Client::new(),
    });

    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(state.clone()))
            .route("/auth", web::post().to(forward_to_auth))
            .route("user", web::get().to(forward_to_user))
    })
    .bind("127.0.0.1")?
    .run()
    .await
}

async fn forward_to_coin_api_playground(
    req: HttpRequest,
    body: web::Bytes,
    state: web::Data<Arc<AppState>>,
) -> Responder {
    let response = match state.client.post("http://127.0.0.1:5001").send().await {
        Ok(response) => response,
        Err(e) => {
            return web::HttpResponse::InternalServerError().body(format!("Request failed: {}", e));
        }
    };
}
