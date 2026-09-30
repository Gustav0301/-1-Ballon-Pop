# Editing the HUD in Studio

The flight HUD is a normal ScreenGui called **BalloonHUD**. Put it in StarterGui once, then change it like any other UI. The game uses your version.

## 1. Install it (once)

In Studio, in **edit mode** (not while playing), open **View → Command Bar** and paste:

```lua
require(workspace.GamePack.Shared.UI.HUDTemplate).Install()
```

(With Rojo, use `require(game.ReplicatedStorage.Shared.UI.HUDTemplate).Install()` instead.)

You'll get **StarterGui → BalloonHUD**. Running it again never deletes your work: the old copy is renamed to `BalloonHUD_Old` and switched off.

## 2. Edit

Change anything: colours, gradients, sizes, positions, fonts, texts, corner radius, outlines, stripes. You can also add decorations such as extra frames, images and icons.

A few things are hidden in edit mode because the game shows them only when needed. Tick **Visible** to see one while you edit it. It doesn't matter what you leave it on:

- `Actions → JumpToFly`
- everything in `Templates` (the cards, the toast, the flying coin and the HP balloon)

**BillboardGuis** (`Templates → BalloonBoard`, `IslandMarker`) don't show in the editor. To edit one, temporarily drag it onto any Part in Workspace, edit it there, then drag it back into `Templates`.

## 3. Keep these names

The code finds pieces by name. Rename or delete any of these and that feature quietly stops updating:

| Piece | Names the code uses |
|---|---|
| Coin counter | `Coins → Holder` (UIScale `Pop`, `Pill → Amount`, `Coin`) |
| Altitude gauge | `Altitude` (attribute `MaxAltitude`), `Bar`, `You`, `Tag → Value` |
| Jump prompt | `Actions → JumpToFly` (UIScale `Pop`, `Pill → Bob`) |
| Land button | `Actions → Land` (`Lip`, `Face → Fill`, `Face → Title`, `Hit`, UIScale `Hover`, `Spot → Text`, `First`) |
| Let out air | `LetOutAir → LetOut` (`Lip`, `Face`, `Hit`, UIScale `Hover`) |
| Island arrow | `IslandArrow → Pointer`, `IslandArrow → Disc → Distance` |
| Card / toast slots | `Cards`, `Toasts` |
| Balloon billboard | `Templates → BalloonBoard` (`Top → Amount`, `Top → Pop`, `Row → Size → Text`, `Row → HP`, `Risk → Fill`, `Risk → Label`) |
| HP balloon | `Templates → HPPip` (`Body`, `Knot`) |
| Island marker | `Templates → IslandMarker → Holder` (`Pop`, `Pill → Name`, `Distance`, `Hint`) |
| Cards | `Templates → BankedCard` (`Pop`, `Panel → Row → Amount / Coin`, `Panel → Where`, `Panel → Bonus → Text`), `Templates → PoppedCard` (`Pop`, `Panel → SizeLine`, `Panel → Row → Lost`) |
| Toast | `Templates → Toast → Pill → Text` |
| Coin fountain | `Templates → FlyingCoin` |
| Screen scaling | every UIScale named `ViewportScale` |
| Keyboard hints | frames named `Key` (hidden on touch and gamepad) |
| Stripes | frames named `Stripes` (kept at 45°) |

Everything else is free: add, remove and rename whatever isn't in this table.

## What the code still sets while playing

- Numbers and dynamic text: coins, height, distance, size, landing messages.
- When things show and hide, and their pop-in animations.
- The pill colours for island states (green LAND HERE!, orange DROP DOWN! / FLOAT UP, red otherwise), and the SIZE chip turning gold at max size.

To change those colours, edit `UIKit.Theme` in `src/shared/UI/UIKit.lua`, or ask me.

## Island notches

The altitude gauge's island notches are made when you install. If the islands move, run the install line again and copy your changes over from `BalloonHUD_Old`.
