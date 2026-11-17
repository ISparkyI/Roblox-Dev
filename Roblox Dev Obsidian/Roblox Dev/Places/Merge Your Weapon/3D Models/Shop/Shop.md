---
tags: [model, building]
status: in-game
updated: 2026-11-16
---

# Shop

← [[Merge Your Weapon - 3D Models|3D Models]]

![[myw_shop_ingame.jpg]]
*Бункер SHOP на спавні, червона зона — вхід у Supply Shop.*

Бункер-магазин **SHOP** на спавні (військовий стиль). Вікно магазину — Shop Window.

## Файли (`Upload/`)
| Файл | Що це |
| --- | --- |
| `myw_bomb_body.obj` | корпус бомби (декор) |
| `myw_flame_cone.obj` | конус полум'я |
| `myw_camo_net.obj` + `myw_camo_net.png` | маскувальна сітка з текстурою |
| `myw_torus_t10/t23/t27/t45.obj`, `myw_halftorus_t23.obj` | кільця / півкільця різної товщини (деталі даху й входу) |
| `myw_sandbag.obj` | мішок з піском (див. також Sandbags) |
| `myw_hazard_diag.png` | діагональні смуги «небезпека» |
| `myw_radiation.png` | знак радіації |

## Вітрини для паків у вікні SHOP (2026-11-14)
Змодельовані для показу зброї в картках паків (`ReplicatedStorage/ShopProps`, скрипт `blender/shopprops.py`), з темною мультяшною обводкою в ViewportFrame.

| Модель | Asset ID | Де |
| --- | --- | --- |
| ShopBox (ящик без кришки) | `94888521124338` | запас (зараз +10/+25 — без контейнера) |
| ShopBarrel (бочка) | `96440997264706` | +50, +100 — зброя стирчить з бочки |
| ShopRack (стенд) | `70643907440205` | 250 — стенд, 500 — золотий стенд |

Файли: `Upload/myw_shopbox.glb`, `myw_shopbarrel.glb`, `myw_shoprack.glb`, `myw_shopprops_preview.png`. Також `Upload/myw_lootcrate.glb` (`109172427488050`) — сундук-скриня, відкинута, не використовується.
