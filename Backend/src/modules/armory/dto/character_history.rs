use crate::modules::armory::dto::{CharacterInfoDto, CharacterGuildDto};

#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
pub struct CharacterHistoryDto {
  pub character_info: CharacterInfoDto,
  pub character_name: String,
  pub guild: Option<CharacterGuildDto>
}