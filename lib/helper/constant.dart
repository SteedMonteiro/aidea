import 'package:flutter/material.dart';

// Client application version number
const clientVersion = '1.0.6';
// Local database version number
const databaseVersion = 25;

const maxRoomNumForNonVIP = 50;
const coinSign = '个';

// API server address
const apiServerURL = 'https://ai-api.aicode.cc';
// const apiServerURL = 'http://localhost';

const settingAPIServerToken = 'api-token';
const settingUserInfo = 'user-info';
const settingUsingGuestMode = 'using-guest-mode';

const chatAnywhereModel = 'openai:gpt-3.5-turbo';
const chatAnywhereRoomId = 1;

const creativeIslandModelTypeText = 'text-generation';
const creativeIslandModelTypeImage = 'image-generation';
const creativeIslandModelTypeImageToImage = 'image-to-image';

const creativeIslandCompletionTypeText = 'text';
const creativeIslandCompletionTypeBase64Image = 'base64-images';
const creativeIslandCompletionTypeURLImage = 'url-images';

// Used to indicate whether the onboarding page has been loaded
// Only the onboarding page will be loaded when first installed
const settingOnBoardingLoaded = 'on-boarding-loaded';
const settingLanguage = 'language';
const settingServerURL = 'server-url';
// Background image
const settingBackgroundImage = 'background-image';
const settingBackgroundImageBlur = 'background-image-blur';

const settingOpenAISelfHosted = 'openai-self-hosted';
const settingDeepAISelfHosted = 'deepai-self-hosted';
const settingStabilityAISelfHosted = 'stabilityai-self-hosted';
const settingImageManagerSelfHosted = 'image-manager-self-hosted';

const settingThemeMode = "dark-mode";
const settingImglocToken = 'imgloc-token';
const chatMessagePerPage = 300;
const contextBreakKey = 'context-break';
const defaultChatModel = 'gpt-3.5-turbo';
const defaultChatModelName = 'GPT-3.5';
const defaultImageModel = 'DALL·E';
const defaultModelNotChatDesc = 'This model does not support context and can only be used for single-turn conversation';

// AI model types
const modelTypeOpenAI = 'openai';
const modelTypeDeepAI = 'deepai';
const modelTypeLeapAI = "leapai";
const modelTypeStabilityAI = 'stabilityai';
const modelTypeFromston = 'fromston';
const modelTypeGetimg = 'getimgai';

final modelTypeTagColors = <String, Color>{
  modelTypeOpenAI: Colors.blue,
  modelTypeDeepAI: Colors.green,
  modelTypeStabilityAI: Colors.purple,
  modelTypeLeapAI: Colors.orange,
  modelTypeFromston: Colors.blueAccent,
  modelTypeGetimg: Colors.pinkAccent,
};

// OpenAI related settings
const settingOpenAIAPIToken = "openai-token";
const settingOpenAIOrganization = 'openai-organization';
const settingOpenAITemperature = "openai-temperature";
const settingOpenAIModel = "openai-model";
const settingOpenAIURL = "openai-url";
const defaultOpenAIServerURL = 'https://api.openai.com';

// DeepAI related settings
const settingDeepAIURL = 'deepai-url';
const settingDeepAIAPIToken = 'deepai-token';
const defaultDeepAIServerURL = 'https://api.deepai.org';

// StabilityAI related settings
const settingStabilityAIURL = 'stabilityai-url';
const settingStabilityAIAPIToken = 'stabilityai-token';
const settingStabilityAIOrganization = 'stabilityai-organization';
const defaultStabilityAIURL = 'https://api.stability.ai';

// WeChat configuration
const weixinAppId = 'wx52cc036cc770406d';
const universalLink = 'https://ai.aicode.cc/wechat-login/';

// Image hosting information
const qiniuImageTypeAvatar = 'avatar';
const qiniuImageTypeThumb = 'thumb';
const qiniuImageTypeThumbMedium = 'thumb_500';