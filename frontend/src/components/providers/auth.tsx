import { useLogoutMutation } from "../../crud/auth";
import { useCallback, useMemo, useState } from "react";
import { UserSchema } from "../../api-client";
import { AuthContext } from "../context/auth";

type AuthProviderProps = {
  children: React.ReactNode;
};

export const AuthProvider = ({ children }: AuthProviderProps) => {
  const { mutate } = useLogoutMutation();
  const [user, setUser] = useState<UserSchema | undefined>(undefined);

  const login = useCallback(
    (user: UserSchema) => {
      setUser(user);
    },
    [setUser],
  );

  const logout = useCallback(() => {
    // @ts-expect-error - issues with mutate signature
    mutate(null, {
      onSuccess: () => {
        setUser(undefined);
      },
    });
  }, [setUser, mutate]);

  const value = useMemo(
    () => ({
      user,
      login,
      logout,
    }),
    [user, login, logout],
  );
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
