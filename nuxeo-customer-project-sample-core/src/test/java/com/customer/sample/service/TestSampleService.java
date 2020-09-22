package com.customer.sample.service;

import static org.junit.Assert.assertNotNull;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.nuxeo.ecm.platform.test.PlatformFeature;
import org.nuxeo.runtime.test.runner.Deploy;
import org.nuxeo.runtime.test.runner.Features;
import org.nuxeo.runtime.test.runner.FeaturesRunner;

import javax.inject.Inject;

@RunWith(FeaturesRunner.class)
@Features({ PlatformFeature.class })
@Deploy("com.customer.sample.operation.nuxeo-customer-project-sample-core")
public class TestSampleService {

    @Inject
    protected SampleService sampleservice;

    @Test
    public void testService() {
        assertNotNull(sampleservice);
    }
}
