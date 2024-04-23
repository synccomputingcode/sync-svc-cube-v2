import { datadogRum } from "@datadog/browser-rum";

export const initAnalytics = () => {
  datadogRum.init({
    applicationId: "40db4259-75a2-4b62-974f-7ef1326c53a6",
    clientToken: "pub8343dc732dc7f8589af86b1517dca994",
    site: "us3.datadoghq.com",
    service: "resume",
    env: import.meta.env.MODE,
    sessionSampleRate: 100,
    sessionReplaySampleRate: 20,
    trackUserInteractions: true,
    trackResources: true,
    trackLongTasks: true,
    defaultPrivacyLevel: "mask-user-input",
  });
};
