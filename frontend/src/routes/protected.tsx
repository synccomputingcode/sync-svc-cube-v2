import { useContext } from "react";
import { AuthContext } from "../components/context/auth";
import { Navigate, Outlet } from "react-router-dom";
import { UserContext } from "../components/context/user";

export const AuthenticatedRoute = () => {
  const { user } = useContext(AuthContext);
  if (!user) {
    return <Navigate to="/" replace />;
  }
  return (
    <UserContext.Provider value={{ user }}>
      <Outlet />
    </UserContext.Provider>
  );
};
