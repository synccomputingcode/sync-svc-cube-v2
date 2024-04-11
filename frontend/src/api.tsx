import { Configuration, DefaultApi } from "./api-client";

export const ApiClient = new DefaultApi(
  new Configuration({
    middleware: [
      {
        pre: async (context) => {
          // using middleware to set headers to
          // keep the cookie fresh!
          context.init.headers = {
            ...context.init.headers,
          };
          return context;
        },
      },
    ],

    basePath: import.meta.env.VITE_API_PATH,
  }),
);
