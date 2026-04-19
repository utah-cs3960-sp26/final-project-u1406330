--!strict

-- Spec coverage for World Replica Service plot stand rendering so decorative replica
-- changes stay deterministic, supportable, and separate from placement-plane authority.

local ServerScriptService = game:GetService("ServerScriptService")

local Server = ServerScriptService:WaitForChild("Server")
local WorldReplicaService = require(Server.Services.WorldReplicaService)

return function()
	local oddPlot = {
		index = 1,
		position = {
			x = 50,
			y = 6,
			z = -105,
		},
	}
	local evenPlot = {
		index = 2,
		position = {
			x = -50,
			y = 6,
			z = -105,
		},
	}

	local oddSpecs = WorldReplicaService._test.getPlotStandRenderSpecs(oddPlot)
	local evenSpecs = WorldReplicaService._test.getPlotStandRenderSpecs(evenPlot)
	local floorAppearance = WorldReplicaService._test.getSharedFloorAppearance()
	local lightingSpec = WorldReplicaService._test.getLightingSpec()
	local skyDecorSpec = WorldReplicaService._test.getSkyDecorSpec()
	local worldShellSpec = WorldReplicaService._test.getWorldShellSpecs()
	local vaultPromptSpec = WorldReplicaService._test.getVaultPromptSpec()
	local mineFacadeSpec = WorldReplicaService._test.getMineFacadeSpec()
	local shopFrontSpec = WorldReplicaService._test.getShopFrontSpec()
	local mineLayoutSpec = WorldReplicaService._test.getMineLayoutSpec()
	local shopLayoutSpec = WorldReplicaService._test.getShopLayoutSpec()

	assert(#oddSpecs.stands == 5, "plot stand render specs should include each decorative stand")
	assert(
		oddSpecs.capClearance > 0 and oddSpecs.supportGap > 0,
		"decorative platforms should sit above the plot surface instead of clipping through it"
	)

	for _, stand in ipairs(oddSpecs.stands) do
		assert(
			stand.cap.bottomY >= oddSpecs.surfaceTopY + oddSpecs.capClearance,
			"stand caps should remain fully above the authoritative plot surface"
		)
		assert(
			stand.lip.bottomY > stand.cap.topY,
			"stand lips should float slightly above the cap so their materials do not overlap"
		)
		assert(
			stand.support.topY < stand.cap.bottomY,
			"stand supports should stop below the decorative platform cap"
		)
		assert(stand.accent == nil, "raised player-plot platforms should no longer render decorative line accents")
		assert(stand.cap.material ~= Enum.Material.Neon, "stand caps should not use neon materials")
		assert(stand.lip.material ~= Enum.Material.Neon, "stand lips should not use neon materials")
		assert(stand.marker.material ~= Enum.Material.Neon, "stand markers should not use neon materials")
	end

	local oddBackShelf = oddSpecs.stands[2]
	local evenBackShelf = evenSpecs.stands[2]
	assert(
		oddBackShelf.cap.position.X > oddPlot.position.x and evenBackShelf.cap.position.X < evenPlot.position.x,
		"mirrored side stands should flip horizontally between neighboring plots"
	)

	local centerDais = oddSpecs.stands[1]
	assert(centerDais.lip.size.X < centerDais.cap.size.X and centerDais.lip.size.Z < centerDais.cap.size.Z, "platform lips should stay inset from the cap edges")

	assert(floorAppearance.material == Enum.Material.Grass, "shared floor should read as a grassy baseplate")
	assert(floorAppearance.color.G > floorAppearance.color.R, "shared floor tint should skew green instead of rocky gray")

	assert(lightingSpec.clockTime > 18, "galaxy lighting should stay in an evening sky window")
	assert(lightingSpec.brightness >= 2.7, "world lighting should be bright enough to read the play space at night")
	assert(
		lightingSpec.outdoorAmbient.G >= 175,
		"world lighting should lift the outdoor ambient light so the world is easier to see"
	)
	assert(lightingSpec.atmosphere.density > 0.2, "galaxy lighting should include a visible atmosphere haze")
	assert(lightingSpec.skybox.SkyboxBk ~= nil, "galaxy lighting should provide skybox assets")

	assert(#skyDecorSpec.planets >= 4, "sky decor should include several planets for the galaxy backdrop")
	assert(#skyDecorSpec.nebulae == 0, "sky decor should remove the bulky nebula layers while keeping the space dressing")
	assert(#skyDecorSpec.stars >= 12, "sky decor should include a denser starfield than the earlier sparse backdrop")
	assert(skyDecorSpec.shootingStars.rate > 0, "sky decor should include shooting star particles")
	for _, starSpec in ipairs(skyDecorSpec.stars) do
		assert(starSpec.size.X > 0 and starSpec.size.Y > 0 and starSpec.size.Z > 0, "star decor should have visible size")
		assert(starSpec.transparency < 0.5, "star decor should stay bright enough to read against the sky")
	end

	assert(#worldShellSpec.segments == 4, "world shell should enclose the play space on all four sides")
	assert(#worldShellSpec.crystals >= 9, "world shell should embed more crystals into the cave walls around the baseplate")
	local shellByName = {}
	for _, segment in ipairs(worldShellSpec.segments) do
		shellByName[segment.name] = segment
		assert(segment.size.Y == worldShellSpec.wallHeight, "cave wall segments should share the configured wall height")
		assert(segment.size.X > 0 and segment.size.Z > 0, "cave wall segments should have physical thickness")
	end
	assert(
		shellByName.WestWall ~= nil and shellByName.NorthWall ~= nil and shellByName.SouthWall ~= nil,
		"world shell should expose the named side segments the facade layout depends on"
	)
	assert(
		shellByName.EastWall ~= nil and shellByName.NorthWall ~= nil and shellByName.SouthWall ~= nil,
		"world shell should expose both long side walls for the shared cave shell"
	)
	assert(
		shellByName.WestWall.size.Z >= shellByName.NorthWall.size.X - 30,
		"side cave walls should run deep enough to overlap the north/south shell instead of leaving a slit near the facades"
	)
	assert(
		shellByName.EastWall.size.Z >= shellByName.SouthWall.size.X - 30,
		"both side cave walls should stay long enough to close the mine/shop-side backdrop gap"
	)

	assert(vaultPromptSpec.promptActionText == "Open Vault", "vault prompt should explicitly open the vault")
	assert(vaultPromptSpec.promptObjectText == "Treasure Vault", "vault prompt should identify the vault station")
	assert(string.find(vaultPromptSpec.calloutText, "Press E", 1, true) ~= nil, "vault callout should teach the press E interaction")
	assert(vaultPromptSpec.buildPhysicalStation == false, "vault interaction should no longer require a physical station build")
	assert(vaultPromptSpec.promptOnlyMarker == true, "vault world projection should be prompt-led instead of chest-led")

	assert(mineFacadeSpec.signFont == Enum.Font.FredokaOne, "mine sign should use the same bubbly display font as the HUD")
	assert(mineFacadeSpec.signText == "Geode Mine", "mine facade should keep the expected label text")
	assert(mineFacadeSpec.calloutText == "Mine here to gather Geodes!", "mine callout should use the updated instruction copy")
	assert(mineFacadeSpec.hideInsideZone == true, "mine callout should hide while the player is standing inside the mine zone")
	assert(mineFacadeSpec.hideDistance >= 14, "mine callout should also hide when the player is very near the mine")
	assert(#mineLayoutSpec.shellSeams >= 3, "mine facade should include dedicated seam fillers to close the side-wall gaps")
	assert(
		mineLayoutSpec.faceSize.X >= mineLayoutSpec.targetSize.X,
		"mine facade face should stay wider than the clickable mine target behind it"
	)
	for _, seam in ipairs(mineLayoutSpec.shellSeams) do
		assert(seam.localOffset.Z < mineLayoutSpec.faceOffset.Z, "mine seam fillers should sit behind the visible cave face")
		assert(seam.size.Y >= mineLayoutSpec.faceSize.Y - 2, "mine seam fillers should stay tall enough to cover the visible shell gap")
		assert(seam.size.X >= 5, "mine seam fillers should have enough width to read as cave shoulders instead of thin slivers")
	end
	assert(
		math.abs(mineLayoutSpec.shellSeams[1].localOffset.X) == math.abs(mineLayoutSpec.shellSeams[2].localOffset.X),
		"mine side seam fillers should mirror each other around the cave entrance"
	)
	local westWallInnerFace = shellByName.WestWall.position.X + (shellByName.WestWall.size.X / 2)
	local mineBaseX = westWallInnerFace + 22
	for seamIndex = 1, 2 do
		local seam = mineLayoutSpec.shellSeams[seamIndex]
		local seamMinX = mineBaseX + seam.localOffset.Z - (seam.size.Z / 2)
		assert(
			seamMinX <= westWallInnerFace - 2,
			"mine side seams should overlap the west shell wall enough to remove visible daylight slits"
		)
	end
	local mineCrown = mineLayoutSpec.shellSeams[3]
	local mineCrownMinX = mineBaseX + mineCrown.localOffset.Z - (mineCrown.size.Z / 2)
	assert(
		mineCrownMinX <= westWallInnerFace - 2,
		"mine crown seam should also tie back into the west shell wall so the upper facade stays sealed"
	)

	assert(shopFrontSpec.calloutText == "Buy pickaxes here!", "shop callout should use the updated instruction copy")
	assert(shopFrontSpec.hideDistance >= 12, "shop callout should hide when the player is standing nearby")
	assert(shopFrontSpec.calloutFont == Enum.Font.FredokaOne, "shop callout should use the bubbly display font for consistency")
	assert(#shopLayoutSpec.shellSeams >= 2, "shop facade should include seam-closing returns behind the stall")
	for _, seam in ipairs(shopLayoutSpec.shellSeams) do
		assert(seam.localOffset.X > shopLayoutSpec.backWallOffset.X, "shop seam fillers should sit behind the pickaxe stall back wall")
		assert(seam.size.Y >= shopLayoutSpec.backWallSize.Y, "shop seam fillers should be at least as tall as the back wall they extend")
		assert(seam.size.Z >= 6, "shop seam fillers should have enough depth to close the visible wall opening")
	end
	assert(
		math.abs(shopLayoutSpec.shellSeams[1].localOffset.Z) == math.abs(shopLayoutSpec.shellSeams[2].localOffset.Z),
		"shop seam fillers should mirror across the stall so both ends stay closed"
	)
	local eastWallInnerFace = shellByName.EastWall.position.X - (shellByName.EastWall.size.X / 2)
	local shopBaseX = eastWallInnerFace - 16
	for seamIndex = 1, 2 do
		local seam = shopLayoutSpec.shellSeams[seamIndex]
		local seamMaxX = shopBaseX + seam.localOffset.X + (seam.size.X / 2)
		assert(
			seamMaxX >= eastWallInnerFace + 2,
			"shop side seams should overlap the east shell wall enough to hide the visible facade gap"
		)
	end
	local shopCap = shopLayoutSpec.shellSeams[3]
	local shopCapMaxX = shopBaseX + shopCap.localOffset.X + (shopCap.size.X / 2)
	assert(
		shopCapMaxX >= eastWallInnerFace + 2,
		"shop shell cap should also reach into the east shell wall so the upper seam stays closed"
	)
	assert(
		shopLayoutSpec.shellSeams[1].size.Z / 2 >= math.abs(shopLayoutSpec.shellSeams[1].localOffset.Z) - 6,
		"shop north seam should extend far enough inward to cover the stall shoulder near the wall"
	)
	assert(
		shopLayoutSpec.shellSeams[2].size.Z / 2 >= math.abs(shopLayoutSpec.shellSeams[2].localOffset.Z) - 6,
		"shop south seam should extend far enough inward to cover the opposite stall shoulder near the wall"
	)
end
