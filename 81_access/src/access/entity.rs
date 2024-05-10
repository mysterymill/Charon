use std::fmt::{self, Display};

use diesel::sql_types::{Integer, Unsigned};
use schema::user::dsl::*;

use crate::schema;

pub trait Entity {
    type I: Id;

    fn get_id(&self) -> &Option<Self::I>;

    fn get_node_type_name() -> &'static str;
    
    fn fmt_entity(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let id_str = if self.get_id().is_none() {
            "none".to_string()
        } else {
            self.get_id().as_ref().unwrap().to_string()
        };

        write!(f, "[{}; id: {})]", Self::get_node_type_name(), id_str)
    }
}

pub trait Id: Send + Sync + Clone + Copy {}

impl Id for u32 {
}

impl Id for Unsigned<Integer> {
}

impl Entity {
	type I = Unsigned<Integer>;
	
	fn get_id(&self) -> &Option<Self::I> {
		self.
	}
	
	fn get_node_type_name() -> &'static str {
			todo!()
	}
}