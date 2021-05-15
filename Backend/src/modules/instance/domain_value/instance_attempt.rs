pub struct InstanceAttempt {
    pub attempt_id: u32,
    pub encounter_id: u32,
    pub start_ts: u64,
    pub end_ts: u64,
    pub is_kill: bool
}