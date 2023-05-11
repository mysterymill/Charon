// @generated automatically by Diesel CLI.

diesel::table! {
    config (id) {
        id -> Nullable<Integer>,
        name -> Text,
        enabled -> Bool,
        domain_id -> Integer,
        target_id -> Integer,
        creator_id -> Integer,
        created -> Timestamp,
        updated -> Timestamp,
        value -> Nullable<Text>,
        description -> Nullable<Text>,
    }
}

diesel::table! {
    domain (id) {
        id -> Nullable<Integer>,
        name -> Text,
        enabled -> Bool,
        creator_id -> Integer,
        created -> Timestamp,
        updated -> Timestamp,
        description -> Nullable<Text>,
        parent_id -> Integer,
        owner_id -> Integer,
    }
}

diesel::table! {
    user (id) {
        id -> Nullable<Integer>,
        name -> Text,
        enabled -> Bool,
        creator_id -> Integer,
        created -> Timestamp,
        updated -> Timestamp,
        description -> Nullable<Text>,
        domain_id -> Integer,
    }
}

diesel::joinable!(config -> user (creator_id));

diesel::allow_tables_to_appear_in_same_query!(
    config,
    domain,
    user,
);
