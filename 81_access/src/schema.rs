// @generated automatically by Diesel CLI.

diesel::table! {
    config (id) {
        id -> Unsigned<Integer>,
        #[max_length = 64]
        name -> Varchar,
        enabled -> Bool,
        origin_id -> Unsigned<Integer>,
        target_id -> Unsigned<Integer>,
        creator_id -> Unsigned<Integer>,
        created -> Datetime,
        updated -> Datetime,
        #[max_length = 255]
        value -> Nullable<Varchar>,
        #[max_length = 255]
        description -> Nullable<Varchar>,
    }
}

diesel::table! {
    domain (id) {
        id -> Unsigned<Integer>,
        #[max_length = 64]
        name -> Varchar,
        enabled -> Bool,
        creator_id -> Unsigned<Integer>,
        environment_id -> Unsigned<Integer>,
        created -> Datetime,
        updated -> Datetime,
        #[max_length = 255]
        description -> Nullable<Varchar>,
        parent_id -> Unsigned<Integer>,
        owner_id -> Unsigned<Integer>,
    }
}

diesel::table! {
    environment (id) {
        id -> Unsigned<Integer>,
        #[max_length = 64]
        name -> Varchar,
        #[max_length = 8]
        shorthand -> Varchar,
        enabled -> Bool,
        creator_id -> Unsigned<Integer>,
        created -> Datetime,
        updated -> Datetime,
        #[max_length = 255]
        description -> Nullable<Varchar>,
    }
}

diesel::table! {
    password (id) {
        id -> Unsigned<Integer>,
        #[max_length = 256]
        hash -> Varchar,
        #[max_length = 256]
        salt -> Nullable<Varchar>,
        #[max_length = 12]
        algorithm -> Varchar,
        iterations -> Unsigned<Smallint>,
        preliminary -> Bool,
        created -> Datetime,
        updated -> Datetime,
    }
}

diesel::table! {
    user (id) {
        id -> Unsigned<Integer>,
        #[max_length = 64]
        name -> Varchar,
        enabled -> Bool,
        creator_id -> Unsigned<Integer>,
        password_id -> Unsigned<Integer>,
        created -> Datetime,
        updated -> Datetime,
        #[max_length = 255]
        description -> Nullable<Varchar>,
        origin_id -> Unsigned<Integer>,
    }
}

diesel::joinable!(config -> user (creator_id));
diesel::joinable!(domain -> environment (environment_id));
diesel::joinable!(environment -> user (creator_id));
diesel::joinable!(user -> password (password_id));

diesel::allow_tables_to_appear_in_same_query!(
    config,
    domain,
    environment,
    password,
    user,
);
