import Cookies from "js-cookie";
import { Configuration, DefaultApi } from "./api-client";

const getCSRFToken = (): string | undefined => {
  // fetch django csrf token from cookie
  const token = Cookies.get("csrftoken");
  return token;
};

export const ApiClient = new DefaultApi(
  new Configuration({
    credentials: "include",
    middleware: [
      {
        pre: async (context) => {
          // using middleware to set headers to
          // keep the cookie fresh!
          const token = getCSRFToken();
          context.init.headers = {
            ...context.init.headers,
            ...(token ? { "X-CSRFToken": token } : {}),
          };
          return context;
        },
      },
    ],
    basePath: import.meta.env.VITE_API_PATH,
  }),
);
