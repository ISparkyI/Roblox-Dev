-- Табличка власника ніші. Система ніш ставить атрибут OwnerName на OwnerSign.
local board = script.Parent
local function update()
	local n = board:GetAttribute("OwnerName")
	local text = (n and n ~= "") and (n .. "'s Mine") or "Empty Mine"
	for _, g in board:GetChildren() do
		if g:IsA("SurfaceGui") and g:FindFirstChild("Owner") then g.Owner.Text = text end
	end
end
board:GetAttributeChangedSignal("OwnerName"):Connect(update)
update()
