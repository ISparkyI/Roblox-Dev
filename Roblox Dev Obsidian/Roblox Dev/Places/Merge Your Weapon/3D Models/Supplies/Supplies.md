---
tags: [model-class, supply]
status: model-ready
updated: 2026-11-15
---

# Supplies

← [[Merge Your Weapon - 3D Models|3D Models]]

Розхідники для бою (10 штук). Як працюють, ціни й відкати — у `GDD - Supplies`.

![[myw_supplies_workshop.png]]

| Модель | Українською | Рідкість | В Explorer |
| --- | --- | --- | --- |
| [[Places/Merge Your Weapon/3D Models/Supplies/Bandage/Bandage\|Bandage]] | Бинт | Common | `S01_Bandage` |
| [[Places/Merge Your Weapon/3D Models/Supplies/EnergyDrink/EnergyDrink\|Energy Drink]] | Енергетик | Common | `S02_EnergyDrink` |
| [[Places/Merge Your Weapon/3D Models/Supplies/Mine/Mine\|Mine]] | Міна | Uncommon | `S03_Mine` |
| [[Places/Merge Your Weapon/3D Models/Supplies/Medkit/Medkit\|Medkit]] | Аптечка | Uncommon | `S04_Medkit` |
| [[Places/Merge Your Weapon/3D Models/Supplies/Grenade/Grenade\|Grenade]] | Граната | Rare | `S05_Grenade` |
| [[Places/Merge Your Weapon/3D Models/Supplies/Molotov/Molotov\|Molotov]] | Молотов | Rare | `S06_Molotov` |
| [[Places/Merge Your Weapon/3D Models/Supplies/BodyArmor/BodyArmor\|Body Armor]] | Бронежилет | Rare | `S07_BodyArmor` |
| [[Places/Merge Your Weapon/3D Models/Supplies/IceGrenade/IceGrenade\|Ice Grenade]] | Крижана граната | Epic | `S08_IceGrenade` |
| [[Places/Merge Your Weapon/3D Models/Supplies/KamikazeDrone/KamikazeDrone\|Kamikaze Drone]] | Дрон-камікадзе | Epic | `S09_KamikazeDrone` |
| [[Places/Merge Your Weapon/3D Models/Supplies/Turret/Turret\|Turret]] | Турель | Legendary | `S10_Turret` |

## Вітрина
- `Workspace/SupplyWorkshop` — платформа «SUPPLY WORKSHOP (dev only)»: `Floor`, `Label`, `Cells` (клітинки), `Supplies` (моделі). Над кожною — табличка «НАЗВА · РІДКІСТЬ».
- У грі вітрину видаляє `DevCleanup` (список `DEV_ONLY`), гравці її не бачать.
- Моделі зібрані з Part у Studio (блоковий стиль), рухомі частини — окремі вузли `*_Node`; анімації — `SupplyIdleAnimator`.
- Копії для гри — `ReplicatedStorage/SupplyModels` (без тегів анімації, Anchored, без колізій): іконки в Supply Shop Window.
