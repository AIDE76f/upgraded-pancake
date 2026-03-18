local player = game.Players.LocalPlayer
local guiParent = player:WaitForChild("PlayerGui")

if guiParent:FindFirstChild("PhysicalCarScanner") then
    guiParent.PhysicalCarScanner:Destroy()
end

--------------------------------------------------
-- 1. تصميم واجهة الرادار
--------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PhysicalCarScanner"
screenGui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 280)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -140)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "🌍 رادار سيارات السيرفر الحالي"
title.TextColor3 = Color3.fromRGB(255, 150, 50)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = mainFrame

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 1, -100)
infoLabel.Position = UDim2.new(0, 10, 0, 50)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "جاري مسح الخريطة الفعلية..."
infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 16
infoLabel.TextWrapped = true
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 100, 0, 35)
closeBtn.Position = UDim2.new(0.5, -50, 1, -45)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "إغلاق"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

--------------------------------------------------
-- 2. دالة تحويل الأرقام العربية
--------------------------------------------------
local function convertArabicNumbers(str)
    local map = {
        ["٠"]="0", ["١"]="1", ["٢"]="2", ["٣"]="3", ["٤"]="4",
        ["٥"]="5", ["٦"]="6", ["٧"]="7", ["٨"]="8", ["٩"]="9",
        ["٫"]="", ["،"]="", [","]="", [" "]="", ["\n"]=""
    }
    local res = str
    for ar, en in pairs(map) do
        res = string.gsub(res, ar, en)
    end
    return res
end

--------------------------------------------------
-- 3. المسح الفيزيائي العميق (Workspace Only)
--------------------------------------------------
local highestPrice = 0
local mostExpensiveCar = nil

-- مسح عالم اللعبة فقط (السيارات الموجودة على الأرض)
for _, obj in pairs(workspace:GetDescendants()) do
    if obj:IsA("Model") then
        local currentCarPrice = 0
        
        -- الطريقة أ: فحص الخصائص المدمجة (Attributes) التي يستخدمها المطورون الجدد
        for attrName, attrVal in pairs(obj:GetAttributes()) do
            local lowerName = string.lower(attrName)
            if type(attrVal) == "number" and (string.find(lowerName, "price") or string.find(lowerName, "cost") or string.find(lowerName, "value")) then
                if attrVal > currentCarPrice then currentCarPrice = attrVal end
            end
        end
        
        -- الطريقة ب: فحص محتويات المجسم من قيم مخفية أو لوحات 3D
        for _, child in pairs(obj:GetDescendants()) do
            
            -- 1. البحث عن قيم برمجية مخفية (IntValue / NumberValue)
            if child:IsA("IntValue") or child:IsA("NumberValue") then
                local lowerName = string.lower(child.Name)
                if string.find(lowerName, "price") or string.find(lowerName, "cost") or string.find(lowerName, "value") or string.find(lowerName, "سعر") then
                    if child.Value > currentCarPrice then currentCarPrice = child.Value end
                end
            end
            
            -- 2. البحث عن لوحات 3D فوق السيارة (BillboardGui أو SurfaceGui)
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                pcall(function()
                    local text = child.Text
                    if text and (string.find(text, "ريال") or string.find(text, "سعر")) then
                        local cleanText = convertArabicNumbers(text)
                        local numStr = string.match(cleanText, "%d+")
                        if numStr then
                            local num = tonumber(numStr)
                            -- استبعاد الأرقام الصغيرة لكي لا نلتقط "الموديل 2017" على أنه سعر
                            if num and num > 5000 and num > currentCarPrice then 
                                currentCarPrice = num 
                            end
                        end
                    end
                end)
            end
        end
        
        -- إذا وجدنا أن هذه السيارة هي الأغلى حتى الآن في السيرفر
        if currentCarPrice > highestPrice then
            -- للتحقق من أنها سيارة فعلاً وليست مبنى معروض للبيع (تحتوي على مقعد قيادة أو عجلات)
            local isCar = obj:FindFirstChildWhichIsA("VehicleSeat", true) or obj:FindFirstChild("DriveSeat", true) or obj:FindFirstChild("Wheels") or obj:FindFirstChild("Body")
            
            if isCar or obj.Name ~= "Workspace" then
                highestPrice = currentCarPrice
                mostExpensiveCar = obj
            end
        end
    end
end

--------------------------------------------------
-- 4. عرض النتيجة
--------------------------------------------------
if mostExpensiveCar and highestPrice > 0 then
    local carName = mostExpensiveCar.Name
    local pos = mostExpensiveCar:GetPivot().Position
    local formattedPosition = string.format("X: %.1f | Y: %.1f | Z: %.1f", pos.X, pos.Y, pos.Z)
    
    infoLabel.Text = 
        "✅ تم العثور على سيارة متوفرة في السيرفر!\n\n" ..
        "🏷️ اسم المجسم: " .. carName .. "\n\n" ..
        "💰 السعر: " .. tostring(highestPrice) .. " ريال\n\n" ..
        "📍 الإحداثيات:\n" .. formattedPosition
else
    infoLabel.Text = "❌ لم يتم العثور على سيارات معروضة للبيع حالياً في هذا السيرفر.\nقد يكون اللاعبون لم يعرضوا سياراتهم بعد، أو أن الأسعار مخفية بطريقة مختلفة."
end
