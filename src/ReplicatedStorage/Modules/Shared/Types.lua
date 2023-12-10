local CharacterUtil = require(script.Parent.CharacterUtil)
export type LocalMurderer = {
	knife: KnifeModel,
	character: CharacterUtil.Character,
	knifeMap: { [number]: number },
	throwPose: PoseData,
	lastHeld: number,
	holding: boolean,
}

export type ClientMurderer = LocalMurderer & {
	knifeId: number,
	lastThrown: number,
}

export type KnifeModel = Model & {
	Handle: BasePart & {
		Grip: Attachment,
	},
}

export type PoseData = { [Motor6D]: CFrame }

return {}
