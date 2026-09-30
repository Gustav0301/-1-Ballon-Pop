--!strict
-- UIKit: the building blocks for every menu, in the Shop style (docs/UI_STYLE.md):
-- bright red panels with a thick dark outline, diagonal lighter stripes on headers,
-- big white rounded type with a dark stroke, chunky buttons with a darker "lip" under
-- the face, gold coins. Everything is plain UI instances (no image uploads needed),
-- so it imports 1:1 and recolours from one theme table.

local TweenService = game:GetService("TweenService")

local UIKit = {}

UIKit.Font = Font.fromEnum(Enum.Font.FredokaOne)

UIKit.Theme = {
	Outline = Color3.fromHex("2A1020"),
	Text = Color3.fromHex("FFFFFF"),
	Red = Color3.fromHex("E0282E"),
	RedTop = Color3.fromHex("FF4A4F"),
	RedDark = Color3.fromHex("A8141C"),
	RedStripe = Color3.fromHex("FF6A6E"),
	Gold = Color3.fromHex("FFC83D"),
	GoldTop = Color3.fromHex("FFE27A"),
	GoldDark = Color3.fromHex("E08A12"),
	GoldLip = Color3.fromHex("B8650B"),
	Green = Color3.fromHex("3CCB4A"),
	GreenTop = Color3.fromHex("8BF27A"),
	GreenLip = Color3.fromHex("1E8A34"),
	Blue = Color3.fromHex("2F8CFF"),
	BlueTop = Color3.fromHex("7CC4FF"),
	BlueLip = Color3.fromHex("1B55B8"),
	Orange = Color3.fromHex("FF8A1F"),
	Dark = Color3.fromHex("3A1830"),
	Shadow = Color3.fromHex("000000"),
}
local T = UIKit.Theme

--------------------------------------------------------------------------------
-- tiny instance helper

function UIKit.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className :: any)
	local parent = nil
	if props then
		for k, v in props do
			if k == "Parent" then
				parent = v
			else
				(inst :: any)[k] = v
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end
local new = UIKit.new

function UIKit.Corner(parent: Instance, radius: UDim?): UICorner
	return new("UICorner", { CornerRadius = radius or UDim.new(0, 12), Parent = parent })
end

function UIKit.Stroke(parent: Instance, thickness: number?, color: Color3?): UIStroke
	return new("UIStroke", {
		Thickness = thickness or 3,
		Color = color or T.Outline,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = parent,
	})
end

-- vertical gloss: `top` fading into `bottom` (the frame's own colour is set to white)
function UIKit.Gloss(frame: GuiObject, top: Color3, bottom: Color3, split: number?)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	local s = split or 0.5
	new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, top),
			ColorSequenceKeypoint.new(s, bottom),
			ColorSequenceKeypoint.new(1, bottom),
		}),
		Parent = frame,
	})
end

-- Diagonal stripes like the Shop header: an overlay with a hard-stepped transparency
-- gradient. The angle is recomputed from the frame's shape so stripes stay at 45 degrees.
function UIKit.Stripes(frame: GuiObject, color: Color3?, strength: number?, bands: number?): Frame
	local n = math.clamp(bands or 10, 2, 10) -- 20 keypoints max = 10 bands
	local alpha = 1 - (strength or 0.35)
	local points = { NumberSequenceKeypoint.new(0, alpha) }
	for i = 1, n - 1 do
		local t = i / n
		local a = if i % 2 == 1 then alpha else 1
		local b = if i % 2 == 1 then 1 else alpha
		table.insert(points, NumberSequenceKeypoint.new(t - 0.0005, a))
		table.insert(points, NumberSequenceKeypoint.new(t, b))
	end
	table.insert(points, NumberSequenceKeypoint.new(1, if (n - 1) % 2 == 1 then 1 else alpha))

	local overlay = new("Frame", {
		Name = "Stripes",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color or T.RedStripe,
		BorderSizePixel = 0,
		ZIndex = frame.ZIndex,
		Parent = frame,
	})
	local corner = frame:FindFirstChildOfClass("UICorner")
	if corner then
		UIKit.Corner(overlay, corner.CornerRadius)
	end
	new("UIGradient", { Transparency = NumberSequence.new(points), Parent = overlay })
	UIKit.BindStripes(overlay)
	return overlay
end

-- keep a stripes overlay at 45 degrees as its frame changes shape (call again on copies)
local function bindOneStripes(overlay: GuiObject)
	local gradient = overlay:FindFirstChildOfClass("UIGradient")
	if not gradient then
		return
	end
	local function angle()
		local s = overlay.AbsoluteSize
		if s.X > 0 and s.Y > 0 then
			gradient.Rotation = math.deg(math.atan2(s.Y, s.X))
		end
	end
	overlay:GetPropertyChangedSignal("AbsoluteSize"):Connect(angle)
	angle()
end

-- `root` itself if it is a stripes overlay, or every "Stripes" frame under it
function UIKit.BindStripes(root: Instance)
	if root.Name == "Stripes" and root:IsA("GuiObject") then
		bindOneStripes(root)
	end
	for _, d in root:GetDescendants() do
		if d.Name == "Stripes" and d:IsA("GuiObject") then
			bindOneStripes(d)
		end
	end
end

--------------------------------------------------------------------------------
-- text

export type LabelProps = {
	Text: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	TextSize: number?,
	Color: Color3?,
	Stroke: number?,
	StrokeColor: Color3?,
	XAlign: Enum.TextXAlignment?,
	Name: string?,
	ZIndex: number?,
	Parent: Instance?,
	Rotation: number?,
}

-- White rounded type with a dark stroke (the Shop title look).
function UIKit.Label(p: LabelProps): TextLabel
	local label = new("TextLabel", {
		Name = p.Name or "Label",
		BackgroundTransparency = 1,
		Size = p.Size or UDim2.fromScale(1, 1),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		FontFace = UIKit.Font,
		Text = p.Text or "",
		TextSize = p.TextSize or 24,
		TextColor3 = p.Color or T.Text,
		TextXAlignment = p.XAlign or Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = p.ZIndex or 1,
		Rotation = p.Rotation or 0,
		Parent = p.Parent,
	})
	local stroke = p.Stroke or math.max(2, math.floor((p.TextSize or 24) / 9))
	if stroke > 0 then
		new("UIStroke", {
			Thickness = stroke,
			Color = p.StrokeColor or T.Outline,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			LineJoinMode = Enum.LineJoinMode.Round,
			Parent = label,
		})
	end
	return label
end

--------------------------------------------------------------------------------
-- panels and buttons

export type PanelProps = {
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Color: Color3?,
	Top: Color3?,
	Radius: number?,
	Outline: number?,
	Stripes: boolean?,
	Name: string?,
	Parent: Instance?,
	ZIndex: number?,
}

-- A red (or any colour) rounded panel with a thick outline and optional stripes.
function UIKit.Panel(p: PanelProps): Frame
	local frame = new("Frame", {
		Name = p.Name or "Panel",
		Size = p.Size,
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		BackgroundColor3 = p.Color or T.Red,
		BorderSizePixel = 0,
		ZIndex = p.ZIndex or 1,
		Parent = p.Parent,
	})
	UIKit.Corner(frame, UDim.new(0, p.Radius or 14))
	UIKit.Stroke(frame, p.Outline or 3.5)
	if p.Top then
		UIKit.Gloss(frame, p.Top, p.Color or T.Red, 0.55)
	end
	if p.Stripes then
		UIKit.Stripes(frame)
	end
	return frame
end

export type ButtonProps = {
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Face: Color3,
	Top: Color3,
	Lip: Color3,
	Radius: number?,
	Name: string?,
	Parent: Instance?,
	LipDepth: number?,
}

export type Button = {
	Frame: Frame, -- positioned container
	Face: Frame, -- put your content in here
	Hit: TextButton, -- input
	Scale: UIScale,
}

-- A chunky button: a darker lip underneath and a glossy face that presses down into it.
function UIKit.Button(p: ButtonProps): Button
	local depth = p.LipDepth or 6
	local radius = UDim.new(0, p.Radius or 14)
	local frame = new("Frame", {
		Name = p.Name or "Button",
		Size = p.Size,
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.AnchorPoint or Vector2.zero,
		BackgroundTransparency = 1,
		Parent = p.Parent,
	})
	local scale = new("UIScale", { Parent = frame })
	local lip = new("Frame", {
		Name = "Lip",
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.fromOffset(0, depth),
		BackgroundColor3 = p.Lip,
		BorderSizePixel = 0,
		Parent = frame,
	})
	UIKit.Corner(lip, radius)
	UIKit.Stroke(lip, 3.5)
	local face = new("Frame", {
		Name = "Face",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = p.Face,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = frame,
	})
	UIKit.Corner(face, radius)
	UIKit.Stroke(face, 3.5)
	UIKit.Gloss(face, p.Top, p.Face, 0.5)
	-- the little white shine on the top edge
	local shine = new("Frame", {
		Name = "Shine",
		Size = UDim2.new(1, -18, 0, 5),
		Position = UDim2.new(0.5, 0, 0, 5),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = face,
	})
	UIKit.Corner(shine, UDim.new(1, 0))
	new("TextButton", {
		Name = "Hit",
		Size = UDim2.new(1, 0, 1, depth),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 20,
		AutoButtonColor = false,
		Parent = frame,
	})
	scale.Name = "Hover"
	return UIKit.BindButton(frame)
end

-- Hooks up the press / hover animation on a button built by UIKit.Button (also one that
-- was saved in StarterGui and edited). Needs children "Face", "Hit" and a UIScale "Hover";
-- "Lip" is optional (its Y offset is how far the face presses down).
function UIKit.BindButton(frame: Frame): Button
	local face = frame:WaitForChild("Face") :: Frame
	local hit = frame:WaitForChild("Hit") :: TextButton
	local scale = frame:FindFirstChild("Hover") :: UIScale?
	if not scale then
		scale = new("UIScale", { Name = "Hover", Parent = frame })
	end
	local hover = scale :: UIScale
	local lip = frame:FindFirstChild("Lip") :: GuiObject?
	local depth = if lip then lip.Position.Y.Offset else 6
	local rest = face.Position

	local pressed = false
	local function press(on: boolean)
		if pressed == on then
			return
		end
		pressed = on
		local info = TweenInfo.new(if on then 0.06 else 0.18, if on then Enum.EasingStyle.Quad else Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		TweenService:Create(face, info, { Position = if on then rest + UDim2.fromOffset(0, depth - 1) else rest }):Play()
	end
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			press(true)
		end
	end)
	hit.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			press(false)
		end
	end)
	hit.MouseEnter:Connect(function()
		TweenService:Create(hover, TweenInfo.new(0.12), { Scale = 1.04 }):Play()
	end)
	hit.MouseLeave:Connect(function()
		press(false)
		TweenService:Create(hover, TweenInfo.new(0.12), { Scale = 1 }):Play()
	end)
	return { Frame = frame, Face = face, Hit = hit, Scale = hover }
end

-- A small keyboard key chip ("E", "SPACE") shown on PC next to actions.
function UIKit.Key(text: string, parent: Instance?, height: number?): Frame
	local h = height or 26
	local width = math.max(h, 12 + #text * math.floor(h * 0.45))
	local key = new("Frame", {
		Name = "Key",
		Size = UDim2.fromOffset(width, h),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = parent,
	})
	UIKit.Corner(key, UDim.new(0, 7))
	UIKit.Stroke(key, 2.5)
	UIKit.Gloss(key, Color3.new(1, 1, 1), Color3.fromHex("D9D2E6"), 0.6)
	UIKit.Label({ Text = text, TextSize = math.floor(h * 0.62), Color = T.Outline, Stroke = 0, Parent = key })
	return key
end

--------------------------------------------------------------------------------
-- icons (built from frames)

local function circle(props: { [string]: any }): Frame
	local f = new("Frame", props)
	f.BorderSizePixel = 0
	UIKit.Corner(f, UDim.new(1, 0))
	return f
end

-- A gold coin with a raised stud in the middle (stud style).
function UIKit.Coin(size: number, parent: Instance?): Frame
	local coin = circle({
		Name = "Coin",
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = T.GoldDark,
		Parent = parent,
	})
	UIKit.Stroke(coin, math.max(2, size / 16))
	local face = circle({
		Name = "Face",
		Size = UDim2.fromScale(0.8, 0.8),
		Position = UDim2.fromScale(0.5, 0.46),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = coin,
	})
	UIKit.Gloss(face, T.GoldTop, T.Gold, 0.55)
	local stud = circle({
		Name = "Stud",
		Size = UDim2.fromScale(0.44, 0.44),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = face,
	})
	UIKit.Gloss(stud, T.GoldTop, T.GoldDark, 0.35)
	new("UIStroke", { Thickness = math.max(1, size / 26), Color = T.GoldLip, Parent = stud })
	local shine = circle({
		Name = "Shine",
		Size = UDim2.fromScale(0.26, 0.14),
		Position = UDim2.fromScale(0.3, 0.2),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.25,
		Rotation = -30,
		Parent = coin,
	})
	shine.ZIndex = 2
	return coin
end

-- A little stud balloon (circle + knot), used for HP pips and the altitude marker.
function UIKit.BalloonIcon(size: number, color: Color3, parent: Instance?): Frame
	local holder = new("Frame", {
		Name = "BalloonIcon",
		Size = UDim2.fromOffset(size, size * 1.2),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	local knot = new("Frame", {
		Name = "Knot",
		Size = UDim2.fromOffset(size * 0.26, size * 0.26),
		Position = UDim2.new(0.5, 0, 0, size * 0.95),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = 45,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = holder,
	})
	UIKit.Stroke(knot, 2)
	local body = circle({
		Name = "Body",
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = color,
		ZIndex = 2,
		Parent = holder,
	})
	UIKit.Stroke(body, math.max(2, size / 11))
	local shine = circle({
		Name = "Shine",
		Size = UDim2.fromScale(0.24, 0.3),
		Position = UDim2.fromScale(0.3, 0.3),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.3,
		Rotation = 30,
		ZIndex = 3,
		Parent = body,
	})
	local _ = shine
	return holder
end

--------------------------------------------------------------------------------
-- numbers and motion

-- 1234567 -> "1,234,567"; big numbers shorten: 12.5M, 3.4B
function UIKit.Number(n: number): string
	n = math.floor(n)
	local abs = math.abs(n)
	if abs >= 1e9 then
		return string.format("%.1fB", n / 1e9)
	elseif abs >= 1e7 then
		return string.format("%.1fM", n / 1e6)
	end
	local s = tostring(abs)
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return (if n < 0 then "-" else "") .. out
end

-- Short prices: 950, 2.5K, 40K, 1M, 2.5B
function UIKit.Short(n: number): string
	local abs = math.abs(n)
	local function fmt(v: number, suffix: string): string
		local s = if v >= 100 then string.format("%d", math.floor(v)) else string.format("%.1f", math.floor(v * 10) / 10)
		s = s:gsub("%.0$", "")
		return s .. suffix
	end
	if abs >= 1e9 then
		return fmt(n / 1e9, "B")
	elseif abs >= 1e6 then
		return fmt(n / 1e6, "M")
	elseif abs >= 1e3 then
		return fmt(n / 1e3, "K")
	end
	return tostring(math.floor(n))
end

function UIKit.Tween(inst: Instance, time: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local tween = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

-- A quick squash-and-stretch "boing" on a UIScale.
function UIKit.Pop(scale: UIScale, amount: number?)
	scale.Scale = 1 + (amount or 0.18)
	UIKit.Tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
end

return UIKit
