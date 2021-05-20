#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
pub struct SpeedKill {
    pub instance_meta_id: u32,
    pub attempt_id: u32,
    pub encounter_id: u32,
    pub guild_id: u32,
    pub guild_name: String,
    pub server_id: u32,
    pub duration: u64,
}