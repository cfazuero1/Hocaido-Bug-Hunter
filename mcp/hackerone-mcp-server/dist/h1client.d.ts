export interface SearchReportsOpts {
    query?: string;
    program?: string;
    severity?: string;
    state?: string;
    page_size?: number;
    page_number?: number;
    sort?: string;
}
export declare function searchReports(opts?: SearchReportsOpts): Promise<{
    id: any;
    title: any;
    state: any;
    substate: any;
    severity: any;
    created_at: any;
    disclosed_at: any;
    bounty_awarded_at: any;
    bounty_amount: any;
    bounty_bonus: any;
    weakness: any;
    program: any;
}[]>;
export declare function getReport(reportId: string): Promise<{
    id: any;
    title: any;
    state: any;
    created_at: any;
    closed_at: any;
    triaged_at: any;
    bounty_awarded_at: any;
    disclosed_at: any;
    severity: any;
    cvss_score: any;
    cvss_vector: {
        attack_vector: any;
        attack_complexity: any;
        privileges_required: any;
        user_interaction: any;
        scope: any;
        confidentiality: any;
        integrity: any;
        availability: any;
    } | null;
    bounty_amount: any;
    bounty_bonus: any;
    vulnerability_information: any;
    impact: any;
    weakness: any;
    weakness_id: any;
    program: any;
    structured_scope: any;
    structured_scope_type: any;
    attachments: any;
}>;
export declare function getReportActivities(reportId: string, _pageSize?: number): Promise<any>;
export declare function listPrograms(pageSize?: number): Promise<{
    id: any;
    handle: any;
    name: any;
    offers_bounties: any;
    state: any;
    started_accepting_at: any;
    submission_state: any;
}[]>;
export declare function getProgramDetails(handle: string): Promise<{
    id: any;
    handle: any;
    name: any;
    url: any;
    offers_bounties: any;
    state: any;
    submission_state: any;
    started_accepting_at: any;
    policy: any;
    response_efficiency_percentage: any;
    average_time_to_first_program_response: any;
    average_time_to_report_resolved: any;
    average_time_to_bounty_awarded: any;
    allow_bounty_splitting: any;
    bookmarked: any;
}>;
export declare function getProgramScope(handle: string, pageSize?: number): Promise<{
    id: any;
    asset_type: any;
    asset_identifier: any;
    eligible_for_bounty: any;
    eligible_for_submission: any;
    instruction: any;
    max_severity: any;
    created_at: any;
}[]>;
export declare function getProgramWeaknesses(handle: string, pageSize?: number): Promise<{
    id: any;
    name: any;
    description: any;
    external_id: any;
}[]>;
export declare function getEarnings(pageSize?: number): Promise<any>;
export declare function getHackerProfile(): Promise<{
    id: any;
    username: any;
    name: any;
    bio: any;
    reputation: any;
    signal: any;
    impact: any;
    rank: any;
    created_at: any;
    hackerone_triager: any;
}>;
export declare function getBalance(): Promise<any>;
export declare function getReportSummary(reportId: string): Promise<{
    conversation: any;
    id: any;
    title: any;
    state: any;
    created_at: any;
    closed_at: any;
    triaged_at: any;
    bounty_awarded_at: any;
    disclosed_at: any;
    severity: any;
    cvss_score: any;
    cvss_vector: {
        attack_vector: any;
        attack_complexity: any;
        privileges_required: any;
        user_interaction: any;
        scope: any;
        confidentiality: any;
        integrity: any;
        availability: any;
    } | null;
    bounty_amount: any;
    bounty_bonus: any;
    vulnerability_information: any;
    impact: any;
    weakness: any;
    weakness_id: any;
    program: any;
    structured_scope: any;
    structured_scope_type: any;
    attachments: any;
}>;
export declare function submitReport(opts: {
    program_handle: string;
    title: string;
    vulnerability_information: string;
    impact?: string;
    severity_rating?: string;
    weakness_id?: string;
    structured_scope_id?: string;
}): Promise<{
    id: any;
    title: any;
    state: any;
    url: string;
}>;
export declare function addComment(reportId: string, message: string, internal?: boolean): Promise<{
    id: any;
    type: any;
    message: any;
    created_at: any;
}>;
export declare function closeReport(reportId: string, message?: string): Promise<{
    id: any;
    type: any;
    message: any;
    created_at: any;
}>;
export declare function searchDisclosedReports(opts: {
    program?: string;
    query?: string;
    page_size?: number;
}): Promise<any>;
