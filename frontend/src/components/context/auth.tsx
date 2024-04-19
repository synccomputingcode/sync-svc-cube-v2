import { createContext } from "react";
import { UserSchema } from "../../api-client";

type AuthContextType = {
  user?: UserSchema;
  login: (data: UserSchema) => void;
  logout: () => void;
};

export const AuthContext = createContext<AuthContextType>({
  user: undefined,
  login: () => {},
  logout: () => {},
});
