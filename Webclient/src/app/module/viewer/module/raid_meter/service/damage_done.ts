import {Injectable} from "@angular/core";
import {InstanceDataService} from "../../../service/instance_data";
import {RaidMeterRow} from "../domain_value/raid_meter_row";
import {BehaviorSubject, Observable} from "rxjs";
import {map, take} from "rxjs/operators";
import {Event} from "../../../domain_value/event";
import {get_unit_id} from "../../../domain_value/unit";
import {EventType} from "../../../domain_value/event_type";
import {MeleeDamage} from "../../../domain_value/melee_damage";
import {SpellDamage} from "../../../domain_value/spell_damage";
import {Damage} from "../../../domain_value/damage";
import {UtilService} from "./util";

@Injectable({
    providedIn: "root",
})
export class DamageDoneService {

    constructor(
        private instanceDataService: InstanceDataService,
        private utilService: UtilService
    ) {
    }

    get rows(): Observable<Array<RaidMeterRow>> {
        return this.rows$.asObservable()
            .pipe(map(rows => rows.sort((left, right) => right.amount - left.amount)));
    }

    private rows$: BehaviorSubject<Array<RaidMeterRow>> = new BehaviorSubject([]);
    private newRows: Map<number, RaidMeterRow>;

    private static extract_damage_from_melee_damage(damage: EventType): number {
        return ((damage as any).MeleeDamage as MeleeDamage).damage;
    }

    private static extract_damage_from_spell_damage(damage: EventType): number {
        return (((damage as any).SpellDamage as SpellDamage).damage as Damage).damage;
    }

    reload(): void {
        this.newRows = new Map();
        this.instanceDataService.melee_damage
            .pipe(take(1))
            .subscribe(damage => {
                damage.forEach(event => this.feed_damage(event, DamageDoneService.extract_damage_from_melee_damage));
                this.commit();
            });
        this.instanceDataService.spell_damage
            .pipe(take(1))
            .subscribe(damage => {
                damage.forEach(event => this.feed_damage(event, DamageDoneService.extract_damage_from_spell_damage));
                this.commit();
            });
    }

    commit(): void {
        this.rows$.next(new Array<RaidMeterRow>(...this.newRows.values()));
    }

    private feed_damage(damage: Event, damage_extract_function: any): void {
        const unit_id = get_unit_id(damage.subject);
        if (this.newRows.has(unit_id)) {
            const row = this.newRows.get(unit_id);
            row.amount += damage_extract_function(damage.event);
        } else {
            this.newRows.set(unit_id, {
                subject: this.utilService.get_row_subject(damage.subject),
                amount: damage_extract_function(damage.event)
            });
        }
    }

}