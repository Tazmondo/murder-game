local CharacterUtil = require(script.Parent.CharacterUtil)

export type LocalMurderer = {
	lastThrown: number,
	knife: KnifeModel,
	character: CharacterUtil.Character,
	knifeMap: { [number]: number },
}

export type ClientMurderer = LocalMurderer & {
	lastClicked: number,
	holding: boolean,
	knifeId: number,
	animations: {
		throw: AnimationTrack,
	},
}

export type KnifeModel = Model & {
	Handle: BasePart & {
		Grip: Attachment,
	},
}

return {}
