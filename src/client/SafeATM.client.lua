local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local p=Players.LocalPlayer
local remote=RS:WaitForChild("ATMTransaction")
local openEvent=RS:WaitForChild("ATMOpen")
local ATM_NAME="QuarantinedATM_119678628566456"
local gui=Instance.new("ScreenGui");gui.Name="SafeATMGui";gui.ResetOnSpawn=false;gui.DisplayOrder=500;gui.Parent=p:WaitForChild("PlayerGui")
local overlay=Instance.new("Frame");overlay.Size=UDim2.fromScale(1,1);overlay.BackgroundColor3=Color3.new(0,0,0);overlay.BackgroundTransparency=.3;overlay.Visible=false;overlay.Parent=gui
local panel=Instance.new("Frame");panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.new(.9,0,0,390);panel.BackgroundColor3=Color3.fromRGB(15,17,20);panel.BorderSizePixel=0;panel.Parent=overlay
local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,18);c.Parent=panel
local function label(t,pos,size,fs,bold)local x=Instance.new("TextLabel");x.BackgroundTransparency=1;x.Position=pos;x.Size=size;x.Text=t;x.TextColor3=Color3.fromRGB(240,240,244);x.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham;x.TextSize=fs;x.TextXAlignment=Enum.TextXAlignment.Left;x.Parent=panel;return x end
label("BANCO DE OURO",UDim2.fromOffset(20,18),UDim2.new(1,-80,0,32),24,true)
local close=Instance.new("TextButton");close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-16,0,16);close.Size=UDim2.fromOffset(42,42);close.BackgroundColor3=Color3.fromRGB(40,43,49);close.Text="X";close.TextColor3=Color3.new(1,1,1);close.Font=Enum.Font.GothamBold;close.TextSize=16;close.BorderSizePixel=0;close.Parent=panel
local cc=Instance.new("UICorner");cc.CornerRadius=UDim.new(0,10);cc.Parent=close
local wl=label("",UDim2.fromOffset(20,72),UDim2.new(.5,-25,0,45),18,true)
local bl=label("",UDim2.new(.5,5,0,72),UDim2.new(.5,-25,0,45),18,true)
local input=Instance.new("TextBox");input.Position=UDim2.fromOffset(20,132);input.Size=UDim2.new(1,-40,0,52);input.BackgroundColor3=Color3.fromRGB(29,32,37);input.TextColor3=Color3.new(1,1,1);input.PlaceholderText="Digite a quantidade de Ouro";input.Text="";input.ClearTextOnFocus=false;input.KeyboardType=Enum.KeyboardType.NumberPad;input.Font=Enum.Font.Gotham;input.TextSize=16;input.BorderSizePixel=0;input.Parent=panel
local ic=Instance.new("UICorner");ic.CornerRadius=UDim.new(0,12);ic.Parent=input
local function btn(t,x)local b=Instance.new("TextButton");b.Position=UDim2.new(x,x==0 and 20 or 5,0,202);b.Size=UDim2.new(.5,-25,0,54);b.BackgroundColor3=Color3.fromRGB(255,205,55);b.TextColor3=Color3.fromRGB(20,20,22);b.Text=t;b.Font=Enum.Font.GothamBold;b.TextSize=16;b.BorderSizePixel=0;b.Parent=panel;local q=Instance.new("UICorner");q.CornerRadius=UDim.new(0,12);q.Parent=b;return b end
local dep=btn("DEPOSITAR",0);local wit=btn("SACAR",.5)
local status=label("ATM SEGURO V10",UDim2.fromOffset(20,278),UDim2.new(1,-40,0,70),14,false);status.TextColor3=Color3.fromRGB(175,180,188);status.TextWrapped=true
local gold=p:WaitForChild("leaderstats"):WaitForChild("Ouro");local bank=p:WaitForChild("Banco")
local function refresh()wl.Text="CARTEIRA\n"..gold.Value.." Ouro";bl.Text="BANCO\n"..bank.Value.." Ouro"end
refresh();gold:GetPropertyChangedSignal("Value"):Connect(refresh);bank:GetPropertyChangedSignal("Value"):Connect(refresh)
local busy=false
local function tx(action)if busy then return end;local n=tonumber(input.Text);if not n or n<1 then status.Text="Digite um valor valido.";return end;busy=true;local ok,success,msg=pcall(function()return remote:InvokeServer(action,n)end);busy=false;if not ok then status.Text="Falha de comunicacao.";return end;status.Text=msg or(success and"Operacao concluida."or"Operacao recusada.");if success then input.Text=""end;refresh()end
dep.Activated:Connect(function()tx("deposit")end);wit.Activated:Connect(function()tx("withdraw")end);close.Activated:Connect(function()overlay.Visible=false end)
openEvent.OnClientEvent:Connect(function()
 refresh()
 status.Text="ATM SEGURO V10"
 overlay.Visible=true
end)
