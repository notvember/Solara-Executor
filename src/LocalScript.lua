local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModelInsertFire = ReplicatedStorage:FindFirstChild("ModelInsertFire")

script.Parent.MouseButton1Click:Connect(function()
	ModelInsertFire:FireServer(script.Parent.Parent.TextBox.Text)
end)