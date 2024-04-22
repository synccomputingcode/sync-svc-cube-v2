import { createContext } from "react";
import { UserSchema } from "../../api-client";

type UserContextType = {
  user: UserSchema;
};
export const UserContext = createContext<UserContextType>({
  user: {} as UserSchema,
});
