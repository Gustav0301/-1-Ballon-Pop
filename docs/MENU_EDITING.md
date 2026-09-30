# The shop, upgrades, balloons and top bar

## How it plays

- **Top bar** (Grow a Garden style): **BALLOONS** (purple, opens your collection), **SHOP**, **SPAWN** and **UPGRADES**. The last three teleport you there. The bar hides while you fly, and teleporting only works on the ground.
- **Balloon Shop.** Walk up to the counter in the Shop stall and press **E** (or tap the prompt).
  - It restocks every 5 minutes for the whole server, with a countdown in the window.
  - Everyone sees the same balloons, but each player has their own quantity of each, so nobody can buy out a Legendary before you get there.
  - Gumball is always in stock. Rarer tiers show up less often: Uncommon 40%, Rare 20%, Epic 5%, Legendary 1%, Mythic 0.2%.
  - When a Legendary or Mythic is in stock, the whole server gets a message and a fanfare.
  - A "NEW!" tag marks balloons you've never owned.
- **Upgrades.** At the Upgrades stall. Levels go from 1 to 50, following section 3.4 of the design doc:
  - Every level gives +2% Max Size, +1% Growth and +1% Earn.
  - Levels 10 and 30 give +1 Toughness, and level 20 gives +1 mutation slot.
  - Level 50 gives Golden Edge (+25% Earn).
  - The cost is `base(tier) × 1.15^level`.
- **My Balloons.** Opened from the purple top-bar button or at the Index stall.
  - It shows everything you own. Tap EQUIP to use a balloon; if you're flying, you'll hold it next flight.
  - Balloons you haven't found yet show as dark silhouettes, with a FOUND x / 17 count.
- Popped balloons stay in your inventory.
- Prices, stock chances and upgrade costs are all in `src/shared/Config/ShopConfig.lua`.

**Testing in Studio:**
- Every balloon is in stock (`ShopConfig.StudioEverything`).
- Type `/coins 1000000` in chat for test money.
- Neither of these works in a live server.

## Editing the look in Studio

It works the same way as the HUD. In **edit mode**, run this in the command bar:

```lua
require(workspace.GamePack.Shared.UI.MenuTemplate).Install()
```

(With Rojo, use `require(game.ReplicatedStorage.Shared.UI.MenuTemplate).Install()` instead.)

This creates **StarterGui → BalloonMenus**. The windows start hidden, so tick `Visible` on `Shop`, `Upgrades` or `Balloons` to edit one. Running the install line again keeps your old version as `BalloonMenus_Old`.

The coin counter now sits under the top bar. If you'd already installed the HUD, move `BalloonHUD → Coins` down to about Y = 100, or run the HUD install line again.

### Names the code relies on

| Piece | Names |
|---|---|
| Top bar | `TopBar → Row → Balloons / Shop / Spawn / Upgrades` (each has `Face`, `Hit`, `Lip`, UIScale `Hover`) |
| Each window | `Shop` / `Upgrades` / `Balloons` → `Window` (UIScale `Pop`, `Close`, `Sub → Text`, `List`, and optionally `Icon`) |
| Header art | `Window → Icon` is a ViewportFrame. Set its **Balloons** attribute (for example `Gumball,Volt,Frost`) to choose which balloons it shows |
| Shop card | `Templates → ShopCard` (`ArtBox → Art`, `Name`, `Tier → Text`, `Stats`, `Special`, `New`, `Left`, `Owned`, `Buy → Face → Row → Price`) |
| Upgrade card | `Templates → UpgradeCard` (`ArtBox → Art`, `Name`, `Level → Text`, `Equipped`, `Stats`, `Next`, `Upgrade → Face → Row → Price`) |
| Balloon card | `Templates → BalloonCard` (`ArtBox → Art`, `Name`, `Level → Text`, `Equip → Face → Text`) |
| Scaling | UIScales named `ViewportScale` |
| Stripes | frames named `Stripes` |

Cards are recoloured by the balloon's tier (their gradient), and buttons turn grey when you can't afford them. Everything else is yours to restyle.
