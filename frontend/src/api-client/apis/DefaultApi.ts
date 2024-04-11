/* tslint:disable */
/* eslint-disable */
/**
 * NinjaAPI
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * The version of the OpenAPI document: 1.0.0
 * 
 *
 * NOTE: This class is auto generated by OpenAPI Generator (https://openapi-generator.tech).
 * https://openapi-generator.tech
 * Do not edit the class manually.
 */


import * as runtime from '../runtime';
import type {
  HealthCheckSchema,
} from '../models/index';
import {
    HealthCheckSchemaFromJSON,
    HealthCheckSchemaToJSON,
} from '../models/index';

/**
 * 
 */
export class DefaultApi extends runtime.BaseAPI {

    /**
     * Hello
     */
    async resumeApiHelloRaw(initOverrides?: RequestInit | runtime.InitOverrideFunction): Promise<runtime.ApiResponse<HealthCheckSchema>> {
        const queryParameters: any = {};

        const headerParameters: runtime.HTTPHeaders = {};

        const response = await this.request({
            path: `/api/healthcheck`,
            method: 'GET',
            headers: headerParameters,
            query: queryParameters,
        }, initOverrides);

        return new runtime.JSONApiResponse(response, (jsonValue) => HealthCheckSchemaFromJSON(jsonValue));
    }

    /**
     * Hello
     */
    async resumeApiHello(initOverrides?: RequestInit | runtime.InitOverrideFunction): Promise<HealthCheckSchema> {
        const response = await this.resumeApiHelloRaw(initOverrides);
        return await response.value();
    }

}
