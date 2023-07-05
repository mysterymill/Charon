use diesel::sqlite::SqliteConnection;
use diesel::r2d2::ConnectionManager;
use r2d2::Pool;
use dotenv::dotenv;
use std::env;


// The SQLite-specific connection pool managing all database connections.
pub type SQLitePool = Pool<ConnectionManager<SqliteConnection>>;


 

pub struct Database {
	pool: SQLitePool,
}

impl Database {
	pub fn new() -> Self {
		// it from the environment within this function
		dotenv().ok();
		let url = env::var("DATABASE_URL").expect("no DB URL");
		let migr = ConnectionManager::<SqliteConnection>::new(url);
		let pool = r2d2::Pool::builder()
			.build(migr)
			.expect("could not build connection pool");
		Database { pool }
	 }
}