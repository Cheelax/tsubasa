export type CardColor = "red" | "blue" | "yellow";

export type CardSize = "xl" | "lg" | "md" | "sm" | "xs";

export type CardAttributeType = "dribble" | "defense";

export type CardKind = "card-black" | "card";

export type CardState = "buffed" | "hurt" | "standard" | "pending";

export type CardData = {
  kind: CardKind;
  size: CardSize;
  color: CardColor;
  hover: boolean;
  captain: boolean;
  dribble: number;
  defense: number;
  energy: number;
  currentDefense?: number;
  player?: string;
  state?: CardState;
};

export interface ExtendedCardProps extends CardData {
  id: string;
  currentDefense?: number;
}
