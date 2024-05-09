use diesel::mysql::MysqlConnection;
use diesel::r2d2::ConnectionManager;
use dotenv::dotenv;
use r2d2::{Pool};
use lazy_static::lazy_static; // 1.4.0
use std::{sync::{Mutex, Arc}, env};
use crate::global;

lazy_static! {
	static ref DATABASE_INSTANCE: Mutex<Arc<Database>> = Mutex::new(Arc::new(Database::new_from_env()));
}

// The SQLite-specific connection pool managing all database connections.
pub type SQLitePool = Pool<ConnectionManager<MysqlConnection>>;

pub struct Database {
	url: String,
	pool: SQLitePool,
}

impl Database {
	fn new_from_env() -> Self {
		// it from the environment within this function
		dotenv().ok();
		let url = env::var(global::ENV_KEY_DATABASE_URL).expect("no DB URL");
		Self::new(url)
	}

	fn new(url: String) -> Self {
		let migr = ConnectionManager::<MysqlConnection>::new(&url);
		let pool = r2d2::Pool::builder()
			.build(migr)
			.expect("could not build connection pool");
		Self { url, pool }
	}

	pub fn get_instance() -> Arc<Self> {
		DATABASE_INSTANCE.lock().unwrap().clone()
	}
}

mod tests {
    use super::*;
	const DB_TEST_URL: &str = "mysql://root:DefaultR00tPwd@127.0.0.1:3306/winston
	";

    #[test]
    fn new_works() {
        let db = Database::new(DB_TEST_URL.to_owned());
        assert_eq!(db.url, DB_TEST_URL.to_owned());
    }

    #[test]
    fn get_instance_works() {
		//env::set_var(global::ENV_KEY_DATABASE_URL, DB_TEST_URL);
        let db = Database::get_instance();
        assert_eq!(db.url, DB_TEST_URL.to_owned());
    }
}
