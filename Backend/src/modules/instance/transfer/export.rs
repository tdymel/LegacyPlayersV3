use crate::modules::armory::Armory;
use crate::modules::data::Data;
use crate::modules::instance::dto::{InstanceFailure, InstanceViewerAttempt, InstanceViewerMeta, InstanceViewerParticipant, RawJson};
use crate::modules::instance::tools::ExportInstance;
use crate::modules::instance::Instance;
use crate::MainDb;
use rocket::State;
use rocket_contrib::json::Json;

#[openapi(skip)]
#[get("/export/events/<instance_meta_id>/<event_type>")]
pub fn get_instance_event_type(me: State<Instance>, instance_meta_id: u32, event_type: u8) -> Result<RawJson, InstanceFailure> {
    me.export_instance_event_type(instance_meta_id, event_type)
        .map(|events| events.join(","))
        .map(|res| RawJson("[".to_owned() + &res + "]"))
}

#[openapi]
#[get("/export/<instance_meta_id>")]
pub fn get_instance_meta(mut db_main: MainDb, me: State<Instance>, data: State<Data>, armory: State<Armory>, instance_meta_id: u32) -> Result<Json<InstanceViewerMeta>, InstanceFailure> {
    me.get_instance_meta(&mut *db_main, &data, &armory, instance_meta_id).map(Json)
}

#[openapi]
#[get("/export/participants/<instance_meta_id>")]
pub fn get_instance_participants(mut db_main: MainDb, me: State<Instance>, armory: State<Armory>, instance_meta_id: u32) -> Result<Json<Vec<InstanceViewerParticipant>>, InstanceFailure> {
    me.get_instance_participants(&mut *db_main, &armory, instance_meta_id).map(Json)
}

#[openapi]
#[get("/export/attempts/<instance_meta_id>")]
pub fn get_instance_attempts(me: State<Instance>, mut db_main: MainDb, instance_meta_id: u32) -> Result<Json<Vec<InstanceViewerAttempt>>, InstanceFailure> {
    me.get_instance_attempts(&mut (*db_main), instance_meta_id).map(Json)
}
