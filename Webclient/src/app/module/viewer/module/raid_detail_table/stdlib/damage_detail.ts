import {HitType} from "../../../domain_value/hit_type";
import {DetailRow} from "../domain_value/detail_row";
import {CONST_AUTO_ATTACK_ID} from "../../../constant/viewer";
import {Damage, extract_mitigation_amount, get_damage_components_total_damage} from "../../../domain_value/damage";
import {create_array_from_nested_map} from "../../../../../stdlib/map_persistance";
import {Event} from "../../../domain_value/event";
import {
    get_aura_application,
    get_melee_damage,
    get_spell_cast,
    get_spell_cause,
    get_spell_damage
} from "../../../extractor/events";
import {detail_row_post_processing} from "./util";

function commit_damage_detail(spell_damage: Array<Event>, melee_damage: Array<Event>, spell_casts: Array<Event>,
                              event_map: Map<number, Event>): Array<[number, Array<[HitType, DetailRow]>]> {
    const ability_details = new Map<number, Map<HitType, DetailRow>>();

    if (melee_damage.length > 0) {
        const melee_details = new Map<HitType, DetailRow>();
        for (const event of melee_damage)
            fill_details(melee_details, get_melee_damage(event));
        ability_details.set(CONST_AUTO_ATTACK_ID, melee_details);
    }

    if (spell_damage.length > 0) {
        for (const event of spell_damage) {
            const spell_damage_event = get_spell_damage(event);
            const [indicator, spell_cause_event] = get_spell_cause(spell_damage_event.spell_cause_id, event_map);
            if (!spell_cause_event)
                return;
            const hit_mask = indicator ? get_spell_cast(spell_cause_event).hit_mask : spell_damage_event.damage.hit_mask;
            const spell_id = indicator ? get_spell_cast(spell_cause_event).spell_id : get_aura_application(spell_cause_event).spell_id;
            const damage = spell_damage_event.damage as Damage;
            if (!ability_details.has(spell_id))
                ability_details.set(spell_id, new Map());
            const details_map = ability_details.get(spell_id);
            fill_details(details_map, {
                damage_components: damage.damage_components,
                hit_mask,
                victim: undefined
            });
        }
    }

    if (spell_casts.length > 0) {
        for (const event of spell_casts) {
            const spell_cast = get_spell_cast(event);
            if (spell_cast.hit_mask.includes(HitType.Crit) || spell_cast.hit_mask.includes(HitType.Hit))
                continue;
            if (!ability_details.has(spell_cast.spell_id))
                ability_details.set(spell_cast.spell_id, new Map());
            const details_map = ability_details.get(spell_cast.spell_id);
            fill_details(details_map, {
                damage_components: [],
                hit_mask: spell_cast.hit_mask,
                victim: undefined
            });
        }
    }

    detail_row_post_processing(ability_details);
    return create_array_from_nested_map(ability_details);
}

function fill_details(details_map: Map<HitType, DetailRow>, damage: Damage): void {
    const hit_type = damage.hit_mask.length === 0 ? HitType.None : damage.hit_mask[0];
    const damage_amount = get_damage_components_total_damage(damage.damage_components);
    if (details_map.has(hit_type)) {
        const details = details_map.get(hit_type);
        ++details.count;
        details.amount += damage_amount;
        details.min = Math.min(details.min, damage_amount);
        details.max = Math.max(details.max, damage_amount);
        details.absorb += extract_mitigation_amount(damage.damage_components, (mitigation) => mitigation.Absorb);
        details.block += extract_mitigation_amount(damage.damage_components, (mitigation) => mitigation.Block);
        details.glance_or_resist += extract_mitigation_amount(damage.damage_components, (mitigation) => mitigation.Resist)
            + extract_mitigation_amount(damage.damage_components, (mitigation) => mitigation.Glance);
    } else {
        details_map.set(hit_type, {
            amount: damage_amount,
            amount_percent: 0,
            average: 0,
            count: 1,
            count_percent: 0,
            hit_type,
            max: damage_amount,
            min: damage_amount,
            glance_or_resist: extract_mitigation_amount(damage.damage_components, (mitigation) => mitigation.Resist)
                + extract_mitigation_amount(damage.damage_components, (mitigation) => mitigation.Glance),
            block: extract_mitigation_amount(damage.damage_components, (mitigation) => mitigation.Block),
            absorb: extract_mitigation_amount(damage.damage_components, (mitigation) => mitigation.Absorb)
        });
    }
}

export {commit_damage_detail};
